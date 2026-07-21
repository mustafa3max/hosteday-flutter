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
  /// Use the specialized [get], [post], [put], [patch], and [delete] methods
  /// when possible.
  Future<Map<String, dynamic>> request({
    required String method,
    required String path,
    Object? id,
    Map<String, dynamic>? body,
    Map<String, Object?>? queryParameters,
    bool withAuth = false,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return http.request(
      method: method,
      path: path,
      id: id,
      body: body,
      queryParameters: queryParameters,
      withAuth: withAuth,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Sends a GET request.
  ///
  /// When [id] is omitted, an index request is sent.
  ///
  /// Search example:
  /// `/services?search=خياطة`
  ///
  /// Filter example:
  /// `/services?filters[status]=active`
  ///
  /// Multiple values for one filter use Laravel array query syntax:
  /// `/services?filters[status][]=active&filters[status][]=pending`
  ///
  /// When [id] is provided, a show request is sent and [filters] must be
  /// omitted.
  ///
  /// Example:
  /// `/services/15`
  Future<Map<String, dynamic>> get(
    String path, {
    Object? id,
    String? search,
    Map<String, Object?>? filters,
    String? relationField,
    Object? relationValue,
    Map<String, Object?>? queryParameters,
    bool withAuth = false,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return http.get(
      path,
      id: id,
      search: search,
      filters: filters,
      relationField: relationField,
      relationValue: relationValue,
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
    bool withAuth = true,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return http.post(
      path,
      body: body,
      queryParameters: queryParameters,
      withAuth: withAuth,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Sends a PUT request to update a resource.
  ///
  /// [id] is appended to [path] as the final path segment.
  Future<Map<String, dynamic>> put(
    String path, {
    required Object id,
    Map<String, dynamic>? body,
    String? relationField,
    Object? relationValue,
    Map<String, Object?>? queryParameters,
    bool withAuth = true,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return http.put(
      path,
      id: id,
      body: body,
      relationField: relationField,
      relationValue: relationValue,
      queryParameters: queryParameters,
      withAuth: withAuth,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Sends a PATCH request to partially update a resource.
  ///
  /// [id] is appended to [path] as the final path segment.
  Future<Map<String, dynamic>> patch(
    String path, {
    required Object id,
    Map<String, dynamic>? body,
    String? relationField,
    Object? relationValue,
    Map<String, Object?>? queryParameters,
    bool withAuth = true,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return http.patch(
      path,
      id: id,
      body: body,
      relationField: relationField,
      relationValue: relationValue,
      queryParameters: queryParameters,
      withAuth: withAuth,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Sends a DELETE request to delete a resource.
  ///
  /// [id] is appended to [path] as the final path segment.
  Future<Map<String, dynamic>> delete(
    String path, {
    required Object id,
    Map<String, dynamic>? body,
    String? relationField,
    Object? relationValue,
    Map<String, Object?>? queryParameters,
    bool withAuth = true,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return http.delete(
      path,
      id: id,
      body: body,
      relationField: relationField,
      relationValue: relationValue,
      queryParameters: queryParameters,
      withAuth: withAuth,
      headers: headers,
      timeout: timeout,
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
      withAuth: false,
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
      withAuth: false,
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
