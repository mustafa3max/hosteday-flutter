import 'auth/hosteday_token_provider.dart';
import 'config/hosteday_config.dart';
import 'http/hosteday_http_client.dart';
import 'realtime/hosteday_realtime_client.dart';

class HosteDayClient {
  final HosteDayConfig config;
  final HosteDayTokenProvider? tokenProvider;

  late final HosteDayHttpClient http;
  late final HosteDayRealtimeClient realtime;

  HosteDayClient({
    required this.config,
    this.tokenProvider,
  }) {
    http = HosteDayHttpClient(
      config: config,
      tokenProvider: tokenProvider,
    );

    realtime = HosteDayRealtimeClient(
      config: config,
      tokenProvider: tokenProvider,
    );
  }

  Future<Map<String, dynamic>> request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    bool withAuth = false,
    Map<String, String>? headers,
  }) {
    return http.request(
      method: method,
      path: path,
      body: body,
      withAuth: withAuth,
      headers: headers,
    );
  }

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

  Future<void> dispose() async {
    await realtime.disconnect();
    http.close();
  }
}