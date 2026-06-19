import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/hosteday_token_provider.dart';
import '../config/hosteday_config.dart';
import '../exceptions/hosteday_exception.dart';

class HosteDayHttpClient {
  final HosteDayConfig config;
  final HosteDayTokenProvider? tokenProvider;
  final http.Client _client;

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
      ...?headers,
    };

    if (withAuth) {
      final token = await tokenProvider?.getToken();

      if (token == null || token.isEmpty) {
        throw const HosteDayException('Missing authentication token.');
      }

      result['Authorization'] = 'Bearer $token';
    }

    return result;
  }

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
          response = await _client.get(uri, headers: requestHeaders);
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
          throw HosteDayException('Unsupported HTTP method: $method');
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
    } catch (e) {
      if (e is HosteDayException) rethrow;

      throw HosteDayException('HosteDay request error.', error: e);
    }
  }

  Map<String, dynamic> _decodeResponse(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return <String, dynamic>{'data': decoded};
  }

  void close() {
    _client.close();
  }
}
