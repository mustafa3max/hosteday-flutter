import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/hosteday_token_provider.dart';
import '../config/hosteday_config.dart';
import '../exceptions/hosteday_exception.dart';

/// A low-level HTTP client for sending requests to the HosteDay API.
///
/// This client handles request headers, optional authentication tokens,
/// JSON request bodies, response decoding, and API error conversion.
class HosteDayHttpClient {
  /// The configuration used to build HosteDay API request URLs.
  final HosteDayConfig config;

  /// The optional provider used to retrieve authentication tokens.
  ///
  /// A token is required when [request] is called with [withAuth] set to true.
  final HosteDayTokenProvider? tokenProvider;

  final http.Client _client;

  /// Creates an HTTP client for the HosteDay API.
  ///
  /// The optional [client] can be provided to supply a custom HTTP client,
  /// such as one configured for testing. When omitted, a default HTTP client
  /// is created automatically.
  HosteDayHttpClient({
    required this.config,
    this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers({
    bool withAuth = false,
    Map<String, String>? headers,
  }) async {
    final result = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...config.defaultHeaders,
      ...?headers,
    };

    if (withAuth) {
      final token = await tokenProvider?.getToken();

      if (token == null || token.trim().isEmpty) {
        throw const HosteDayException(
          'Missing authentication token.',
        );
      }

      result['Authorization'] = 'Bearer ${token.trim()}';
    }

    return result;
  }

  /// Sends a GET request to [path].
  Future<Map<String, dynamic>> get(
    String path, {
    bool withAuth = false,
    Map<String, String>? headers,
  }) {
    return request(
      method: 'GET',
      path: path,
      withAuth: withAuth,
      headers: headers,
    );
  }

  /// Sends a POST request to [path].
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = false,
    Map<String, String>? headers,
  }) {
    return request(
      method: 'POST',
      path: path,
      body: body,
      withAuth: withAuth,
      headers: headers,
    );
  }

  /// Sends a PUT request to [path].
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = false,
    Map<String, String>? headers,
  }) {
    return request(
      method: 'PUT',
      path: path,
      body: body,
      withAuth: withAuth,
      headers: headers,
    );
  }

  /// Sends a PATCH request to [path].
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = false,
    Map<String, String>? headers,
  }) {
    return request(
      method: 'PATCH',
      path: path,
      body: body,
      withAuth: withAuth,
      headers: headers,
    );
  }

  /// Sends a DELETE request to [path].
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = false,
    Map<String, String>? headers,
  }) {
    return request(
      method: 'DELETE',
      path: path,
      body: body,
      withAuth: withAuth,
      headers: headers,
    );
  }

  /// Sends an HTTP request to the HosteDay API.
  ///
  /// The [method] determines the HTTP operation, such as GET, POST, PUT,
  /// PATCH, or DELETE. The [path] is resolved against the configured API
  /// base URL.
  ///
  /// The optional [body] is encoded as JSON for methods that send a payload.
  /// Set [withAuth] to true to include a bearer token obtained from
  /// [tokenProvider]. Additional request headers may be supplied through
  /// [headers].
  ///
  /// Returns the decoded response data as a map.
  ///
  /// Throws a [HosteDayException] when the request method is unsupported, an
  /// authentication token is unavailable, the server returns a non-successful
  /// status code, or a network or decoding error occurs.
  Future<Map<String, dynamic>> request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    bool withAuth = false,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = config.uri(path);

      final requestHeaders = await _headers(
        withAuth: withAuth,
        headers: headers,
      );

      final normalizedMethod = method.toUpperCase();

      late final http.Response response;

      switch (normalizedMethod) {
        case 'GET':
          response = await _client.get(
            uri,
            headers: requestHeaders,
          );
          break;

        case 'POST':
          response = await _client.post(
            uri,
            headers: requestHeaders,
            body: jsonEncode(body ?? <String, dynamic>{}),
          );
          break;

        case 'PUT':
          response = await _client.put(
            uri,
            headers: requestHeaders,
            body: jsonEncode(body ?? <String, dynamic>{}),
          );
          break;

        case 'PATCH':
          response = await _client.patch(
            uri,
            headers: requestHeaders,
            body: jsonEncode(body ?? <String, dynamic>{}),
          );
          break;

        case 'DELETE':
          response = await _client.delete(
            uri,
            headers: requestHeaders,
            body: body == null ? null : jsonEncode(body),
          );
          break;

        default:
          throw HosteDayException(
            'Unsupported HTTP method: $method',
          );
      }

      final decoded = _decodeResponse(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HosteDayException(
          decoded['message']?.toString() ?? 'HosteDay request failed.',
          statusCode: response.statusCode,
          error: decoded,
        );
      }

      return decoded;
    } on HosteDayException {
      rethrow;
    } catch (error) {
      throw HosteDayException(
        'HosteDay request error.',
        error: error,
      );
    }
  }

  Map<String, dynamic> _decodeResponse(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(body);

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

  /// Closes the underlying HTTP client and releases its resources.
  ///
  /// No additional requests should be made through this instance after calling
  /// this method.
  void close() {
    _client.close();
  }
}
