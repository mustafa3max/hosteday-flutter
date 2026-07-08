import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/hosteday_token_provider.dart';
import '../config/hosteday_config.dart';
import '../exceptions/hosteday_exception.dart';

/// A low-level HTTP client for sending requests to the HosteDay API.
///
/// This client handles:
/// - Request URL building.
/// - Default HosteDay headers.
/// - Optional bearer authentication.
/// - JSON request bodies.
/// - JSON response decoding.
/// - Laravel-style validation errors.
/// - API and network error conversion.
class HosteDayHttpClient {
  /// The configuration used to build HosteDay API request URLs.
  final HosteDayConfig config;

  /// The optional provider used to retrieve authentication tokens.
  ///
  /// A token is required when [request] is called with [withAuth] set to true.
  final HosteDayTokenProvider? tokenProvider;

  /// Default timeout used for all requests.
  final Duration timeout;

  final http.Client _client;

  /// Creates an HTTP client for the HosteDay API.
  ///
  /// The optional [client] can be provided to supply a custom HTTP client,
  /// such as one configured for testing.
  HosteDayHttpClient({
    required this.config,
    this.tokenProvider,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

  /// Sends a GET request to [path].
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, Object?>? queryParameters,
    bool withAuth = false,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return request(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      withAuth: withAuth,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Sends a POST request to [path].
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, Object?>? queryParameters,
    bool withAuth = false,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return request(
      method: 'POST',
      path: path,
      body: body,
      queryParameters: queryParameters,
      withAuth: withAuth,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Sends a PUT request to [path].
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, Object?>? queryParameters,
    bool withAuth = false,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return request(
      method: 'PUT',
      path: path,
      body: body,
      queryParameters: queryParameters,
      withAuth: withAuth,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Sends a PATCH request to [path].
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, Object?>? queryParameters,
    bool withAuth = false,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return request(
      method: 'PATCH',
      path: path,
      body: body,
      queryParameters: queryParameters,
      withAuth: withAuth,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Sends a DELETE request to [path].
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, Object?>? queryParameters,
    bool withAuth = false,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return request(
      method: 'DELETE',
      path: path,
      body: body,
      queryParameters: queryParameters,
      withAuth: withAuth,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Sends an HTTP request to the HosteDay API.
  ///
  /// The [method] determines the HTTP operation, such as GET, POST, PUT,
  /// PATCH, or DELETE.
  ///
  /// The [path] is resolved against [HosteDayConfig.baseUrl].
  ///
  /// [queryParameters] are appended to the request URL.
  ///
  /// [body] is encoded as JSON for methods that support a payload.
  ///
  /// Set [withAuth] to true to include a bearer token from [tokenProvider].
  ///
  /// Returns the decoded response payload as a map.
  Future<Map<String, dynamic>> request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, Object?>? queryParameters,
    bool withAuth = false,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final normalizedMethod = method.trim().toUpperCase();

    if (!_isSupportedMethod(normalizedMethod)) {
      throw HosteDayException(
        'Unsupported HTTP method: $method',
      );
    }

    final hasJsonBody = body != null &&
        (normalizedMethod == 'POST' ||
            normalizedMethod == 'PUT' ||
            normalizedMethod == 'PATCH' ||
            normalizedMethod == 'DELETE');

    try {
      final uri = _buildUri(
        path,
        queryParameters: queryParameters,
      );

      final requestHeaders = await _headers(
        withAuth: withAuth,
        hasJsonBody: hasJsonBody,
        headers: headers,
      );

      final response = await _send(
        method: normalizedMethod,
        uri: uri,
        headers: requestHeaders,
        body: hasJsonBody ? jsonEncode(body) : null,
      ).timeout(timeout ?? this.timeout);

      final decoded = _decodeResponse(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HosteDayException.fromResponse(
          decoded,
          statusCode: response.statusCode,
        );
      }

      return decoded;
    } on HosteDayException {
      rethrow;
    } on TimeoutException catch (error) {
      throw HosteDayException(
        'HosteDay request timed out.',
        error: error,
      );
    } catch (error) {
      throw HosteDayException(
        'HosteDay request error.',
        error: error,
      );
    }
  }

  Future<Map<String, String>> _headers({
    required bool withAuth,
    required bool hasJsonBody,
    Map<String, String>? headers,
  }) async {
    final result = <String, String>{
      'Accept': 'application/json',
      ...config.defaultHeaders,
    };

    if (hasJsonBody) {
      result['Content-Type'] = 'application/json';
    }

    if (headers != null && headers.isNotEmpty) {
      result.addAll(headers);
    }

    if (withAuth) {
      final token = await tokenProvider?.getToken();
      final cleanToken = token?.trim();

      if (cleanToken == null || cleanToken.isEmpty) {
        throw const HosteDayException(
          'Missing authentication token.',
          statusCode: 401,
        );
      }

      result['Authorization'] = 'Bearer $cleanToken';
    }

    return result;
  }

  Future<http.Response> _send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) {
    switch (method) {
      case 'GET':
        return _client.get(
          uri,
          headers: headers,
        );

      case 'POST':
        return _client.post(
          uri,
          headers: headers,
          body: body,
        );

      case 'PUT':
        return _client.put(
          uri,
          headers: headers,
          body: body,
        );

      case 'PATCH':
        return _client.patch(
          uri,
          headers: headers,
          body: body,
        );

      case 'DELETE':
        return _client.delete(
          uri,
          headers: headers,
          body: body,
        );

      default:
        throw HosteDayException(
          'Unsupported HTTP method: $method',
        );
    }
  }

  Uri _buildUri(
    String path, {
    Map<String, Object?>? queryParameters,
  }) {
    final uri = config.uri(path);

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final cleanedQueryParameters = <String, String>{
      ...uri.queryParameters,
    };

    for (final entry in queryParameters.entries) {
      final value = entry.value;

      if (value == null) {
        continue;
      }

      cleanedQueryParameters[entry.key] = value.toString();
    }

    if (cleanedQueryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(
      queryParameters: cleanedQueryParameters,
    );
  }

  Map<String, dynamic> _decodeResponse(String body) {
    final cleanBody = body.trim();

    if (cleanBody.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(cleanBody);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return <String, dynamic>{
        'data': decoded,
      };
    } on FormatException catch (error) {
      throw HosteDayException(
        'HosteDay returned an invalid JSON response.',
        error: error,
      );
    }
  }

  bool _isSupportedMethod(String method) {
    return method == 'GET' ||
        method == 'POST' ||
        method == 'PUT' ||
        method == 'PATCH' ||
        method == 'DELETE';
  }

  /// Closes the underlying HTTP client and releases its resources.
  ///
  /// No additional requests should be made through this instance after calling
  /// this method.
  void close() {
    _client.close();
  }
}
