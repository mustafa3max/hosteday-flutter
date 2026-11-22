import 'dart:async';
import 'dart:convert';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:http/http.dart' as http;

import '../exceptions/hosteday_exception.dart';

/// Exception thrown when broadcasting channel authorization fails.
class HostedayRealtimeAuthorizationException extends HostedayException
    implements PusherChannelsException {
  /// The underlying HTTP response from the broadcasting authorization endpoint.
  final http.Response? httpResponse;

  const HostedayRealtimeAuthorizationException(
    super.message, {
    super.statusCode = 401,
    this.httpResponse,
    super.response,
    super.error,
  });

  @override
  String toString() => 'HostedayRealtimeAuthorizationException: $message';
}

/// A custom authorization delegate that executes dynamic header evaluation
/// on every authorization request for private, presence, and encrypted channels.
class HostedayChannelAuthorizationDelegate<T extends EndpointAuthorizationData>
    implements EndpointAuthorizableChannelAuthorizationDelegate<T> {
  /// The broadcasting authorization endpoint URI.
  final Uri authorizationEndpoint;

  /// Dynamic callback executed on every authorization attempt to build updated headers.
  final FutureOr<Map<String, String>> Function() headersBuilder;

  /// Parser converting the HTTP response to typed authorization data.
  final EndpointAuthorizableChannelTokenAuthorizationParser<T> parser;

  @override
  final EndpointAuthFailedCallback? onAuthFailed;

  /// Optional HTTP client used to execute the authorization POST request.
  final http.Client? httpClient;

  /// Whether to add `'content-type': 'application/x-www-form-urlencoded'`.
  final bool overrideContentTypeHeader;

  const HostedayChannelAuthorizationDelegate({
    required this.authorizationEndpoint,
    required this.headersBuilder,
    required this.parser,
    this.onAuthFailed,
    this.httpClient,
    this.overrideContentTypeHeader = true,
  });

  @override
  Future<T> authorizationData(String socketId, String channelName) async {
    final dynamicHeaders = await headersBuilder();
    final authHeader =
        dynamicHeaders['Authorization'] ?? dynamicHeaders['authorization'];

    if (authHeader == null || authHeader.trim().isEmpty) {
      throw HostedayRealtimeAuthorizationException(
        'Missing dynamic Authorization bearer token when authorizing channel "$channelName".',
        statusCode: 401,
      );
    }

    final headers = <String, String>{
      ...dynamicHeaders,
      if (overrideContentTypeHeader)
        'content-type': 'application/x-www-form-urlencoded',
    };

    final http.Response response;
    try {
      final client = httpClient;
      if (client != null) {
        response = await client.post(
          authorizationEndpoint,
          headers: headers,
          body: <String, String>{
            'socket_id': socketId,
            'channel_name': channelName,
          },
        );
      } else {
        response = await http.post(
          authorizationEndpoint,
          headers: headers,
          body: <String, String>{
            'socket_id': socketId,
            'channel_name': channelName,
          },
        );
      }
    } catch (exception) {
      rethrow;
    }

    if (response.statusCode != 200) {
      throw HostedayRealtimeAuthorizationException(
        'Broadcasting channel authorization failed with HTTP ${response.statusCode} for "$channelName": '
        '${response.body}',
        statusCode: response.statusCode,
        httpResponse: response,
      );
    }

    return await parser(response);
  }

  /// Factory for private channel authorization delegate.
  static HostedayChannelAuthorizationDelegate<PrivateChannelAuthorizationData>
      forPrivateChannel({
    required Uri authorizationEndpoint,
    required FutureOr<Map<String, String>> Function() headersBuilder,
    EndpointAuthorizableChannelTokenAuthorizationParser<
            PrivateChannelAuthorizationData>?
        parser,
    EndpointAuthFailedCallback? onAuthFailed,
    http.Client? httpClient,
  }) {
    return HostedayChannelAuthorizationDelegate<
        PrivateChannelAuthorizationData>(
      authorizationEndpoint: authorizationEndpoint,
      headersBuilder: headersBuilder,
      parser: parser ?? defaultPrivateChannelParser,
      onAuthFailed: onAuthFailed,
      httpClient: httpClient,
    );
  }

  /// Factory for presence channel authorization delegate.
  static HostedayChannelAuthorizationDelegate<PresenceChannelAuthorizationData>
      forPresenceChannel({
    required Uri authorizationEndpoint,
    required FutureOr<Map<String, String>> Function() headersBuilder,
    EndpointAuthorizableChannelTokenAuthorizationParser<
            PresenceChannelAuthorizationData>?
        parser,
    EndpointAuthFailedCallback? onAuthFailed,
    http.Client? httpClient,
  }) {
    return HostedayChannelAuthorizationDelegate<
        PresenceChannelAuthorizationData>(
      authorizationEndpoint: authorizationEndpoint,
      headersBuilder: headersBuilder,
      parser: parser ?? defaultPresenceChannelParser,
      onAuthFailed: onAuthFailed,
      httpClient: httpClient,
    );
  }

  /// Factory for private encrypted channel authorization delegate.
  static HostedayChannelAuthorizationDelegate<
      PrivateEncryptedChannelAuthorizationData> forPrivateEncryptedChannel({
    required Uri authorizationEndpoint,
    required FutureOr<Map<String, String>> Function() headersBuilder,
    EndpointAuthorizableChannelTokenAuthorizationParser<
            PrivateEncryptedChannelAuthorizationData>?
        parser,
    EndpointAuthFailedCallback? onAuthFailed,
    http.Client? httpClient,
  }) {
    return HostedayChannelAuthorizationDelegate<
        PrivateEncryptedChannelAuthorizationData>(
      authorizationEndpoint: authorizationEndpoint,
      headersBuilder: headersBuilder,
      parser: parser ?? defaultPrivateEncryptedChannelParser,
      onAuthFailed: onAuthFailed,
      httpClient: httpClient,
    );
  }

  /// Default parser for private channels. Supports both standard `{auth: ...}`
  /// and Hosteday envelope `{data: {auth: ...}}`.
  static PrivateChannelAuthorizationData defaultPrivateChannelParser(
    http.Response response,
  ) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException(
        'Invalid JSON returned by broadcasting auth endpoint',
      );
    }

    Map<dynamic, dynamic>? payload;
    if (decoded is Map) {
      if (decoded.containsKey('auth')) {
        payload = decoded;
      } else if (decoded['data'] is Map &&
          (decoded['data'] as Map).containsKey('auth')) {
        payload = decoded['data'] as Map;
      }
    }

    if (payload == null) {
      throw FormatException(
        'Broadcasting auth endpoint returned payload without "auth" key: '
        '${response.body}',
      );
    }

    final auth = payload['auth']?.toString();
    if (auth == null || auth.isEmpty) {
      throw const FormatException(
        'Broadcasting auth endpoint returned empty "auth" key',
      );
    }

    return PrivateChannelAuthorizationData(authKey: auth);
  }

  /// Default parser for presence channels. Supports both standard `{auth: ..., channel_data: ...}`
  /// and Hosteday envelope `{data: {auth: ..., channel_data: ...}}`.
  static PresenceChannelAuthorizationData defaultPresenceChannelParser(
    http.Response response,
  ) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException(
        'Invalid JSON returned by broadcasting auth endpoint',
      );
    }

    Map<dynamic, dynamic>? payload;
    if (decoded is Map) {
      if (decoded.containsKey('auth')) {
        payload = decoded;
      } else if (decoded['data'] is Map &&
          (decoded['data'] as Map).containsKey('auth')) {
        payload = decoded['data'] as Map;
      }
    }

    if (payload == null) {
      throw FormatException(
        'Broadcasting auth endpoint returned payload without "auth" key: '
        '${response.body}',
      );
    }

    final auth = payload['auth']?.toString();
    final rawChannelData = payload['channel_data'];

    if (auth == null || auth.isEmpty) {
      throw const FormatException(
        'Broadcasting auth endpoint returned empty "auth" key',
      );
    }

    String? channelDataEncoded;
    if (rawChannelData is String) {
      channelDataEncoded = rawChannelData;
    } else if (rawChannelData != null) {
      channelDataEncoded = jsonEncode(rawChannelData);
    }

    return PresenceChannelAuthorizationData(
      authKey: auth,
      channelDataEncoded: channelDataEncoded ?? '{}',
    );
  }

  /// Default parser for private encrypted channels.
  static PrivateEncryptedChannelAuthorizationData
      defaultPrivateEncryptedChannelParser(
    http.Response response,
  ) {
    final decoded = jsonDecode(response.body) as Map;
    final auth = decoded['auth'] as String;
    final sharedSecret = decoded['shared_secret'] as String;
    final key = base64Decode(sharedSecret);

    return PrivateEncryptedChannelAuthorizationData(
      authKey: auth,
      sharedSecret: key,
    );
  }
}
