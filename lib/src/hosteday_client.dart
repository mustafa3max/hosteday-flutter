import 'auth/hosteday_auth.dart';
import 'auth/hosteday_auth_storage.dart';
import 'auth/hosteday_auth_token_provider.dart';
import 'auth/hosteday_token_provider.dart';
import 'config/hosteday_config.dart';
import 'http/hosteday_http_client.dart';
import 'realtime/hosteday_realtime_client.dart';

/// A high-level client for interacting with HosteDay services.
///
/// This client provides:
/// - HTTP API requests.
/// - Authentication access through [auth].
/// - Realtime access through [realtime].
/// - Realtime event publishing helpers.
///
/// Authentication and user API paths are fixed by HosteDay and are managed
/// internally by [HosteDayAuth].
class HosteDayClient {
  /// The configuration used to connect to HosteDay services.
  final HosteDayConfig config;

  /// Optional external token provider supplied during SDK initialization.
  ///
  /// This is used only as a fallback when there is no active HosteDay auth
  /// session stored in [authStorage].
  final HosteDayTokenProvider? tokenProvider;

  /// Storage used to persist the authenticated user session.
  final HosteDayAuthStorage authStorage;

  /// Token provider used internally by HTTP and realtime clients.
  ///
  /// It reads the active HosteDay auth session first, then falls back to the
  /// externally supplied [tokenProvider] when available.
  late final HosteDayTokenProvider effectiveTokenProvider;

  /// The HTTP client responsible for executing API requests.
  late final HosteDayHttpClient http;

  /// The realtime client responsible for managing live connections.
  late final HosteDayRealtimeClient realtime;

  /// Authentication service for the current HosteDay application.
  late final HosteDayAuth auth;

  /// Creates a [HosteDayClient] using the provided [config].
  ///
  /// [authStorage] defaults to in-memory storage. For production apps, pass
  /// a secure storage implementation.
  HosteDayClient({
    required this.config,
    this.tokenProvider,
    HosteDayAuthStorage? authStorage,
  }) : authStorage = authStorage ?? MemoryHosteDayAuthStorage() {
    final authTokenProvider = HosteDayAuthTokenProvider(
      storage: this.authStorage,
    );

    effectiveTokenProvider = HosteDayCombinedTokenProvider(
      primary: authTokenProvider,
      fallback: tokenProvider,
    );

    http = HosteDayHttpClient(
      config: config,
      tokenProvider: effectiveTokenProvider,
    );

    realtime = HosteDayRealtimeClient(
      config: config,
      tokenProvider: effectiveTokenProvider,
    );

    auth = HosteDayAuth(
      config: config,
      http: http,
      storage: this.authStorage,
      onSessionCleared: realtime.disconnect,
    );
  }

  /// Restores the saved authentication session.
  ///
  /// Call this once during SDK initialization so [auth] can load the stored
  /// session and notify auth state listeners.
  Future<void> initialize() {
    return auth.initialize();
  }

  /// Sends a raw HTTP request to the HosteDay API.
  ///
  /// The [method] defines the HTTP method to use, such as `GET`, `POST`,
  /// `PUT`, `PATCH`, or `DELETE`.
  ///
  /// The [path] must be an API path relative to [HosteDayConfig.baseUrl].
  ///
  /// Set [withAuth] to `true` when the request should include the current
  /// user access token.
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

  /// Sends a GET request to the specified API [path].
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

  /// Sends a POST request to the specified API [path].
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

  /// Sends a PUT request to the specified API [path].
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

  /// Sends a PATCH request to the specified API [path].
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

  /// Sends a DELETE request to the specified API [path].
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

  /// Publishes an event to a public HosteDay realtime channel.
  ///
  /// Public events do not require a user access token, but the project API
  /// token is still sent automatically when configured.
  Future<Map<String, dynamic>> publishPublicEvent({
    required String channel,
    required String event,
    required Map<String, dynamic> payload,
  }) {
    return post(
      config.publicEventsPath,
      body: <String, dynamic>{
        'channel': _normalizePublicChannel(channel),
        'event': event,
        'payload': payload,
      },
    );
  }

  /// Publishes an event to a private HosteDay realtime channel.
  ///
  /// A valid authenticated user token is required.
  Future<Map<String, dynamic>> publishPrivateEvent({
    required String channel,
    required String event,
    required Map<String, dynamic> payload,
  }) {
    return post(
      config.privateEventsPath,
      withAuth: true,
      body: <String, dynamic>{
        'channel': _normalizePrivateChannel(channel),
        'event': event,
        'payload': payload,
      },
    );
  }

  /// Publishes an event to a presence HosteDay realtime channel.
  ///
  /// A valid authenticated user token is required.
  Future<Map<String, dynamic>> publishPresenceEvent({
    required String channel,
    required String event,
    required Map<String, dynamic> payload,
  }) {
    return post(
      config.presenceEventsPath,
      withAuth: true,
      body: <String, dynamic>{
        'channel': _normalizePresenceChannel(channel),
        'event': event,
        'payload': payload,
      },
    );
  }

  /// Releases resources used by the client.
  ///
  /// This disconnects realtime, disposes auth streams, and closes HTTP.
  Future<void> dispose() async {
    await realtime.disconnect();
    await auth.dispose();
    http.close();
  }

  static String _normalizePublicChannel(String channel) {
    return channel.trim();
  }

  static String _normalizePrivateChannel(String channel) {
    final value = channel.trim();

    if (value.startsWith('private-')) {
      return value;
    }

    return 'private-$value';
  }

  static String _normalizePresenceChannel(String channel) {
    final value = channel.trim();

    if (value.startsWith('presence-')) {
      return value;
    }

    return 'presence-$value';
  }
}
