import 'dart:async';

import 'features/hosteday_features.dart';
import 'responses/hosteday_page.dart';
import 'responses/hosteday_response_reader.dart';

import 'package:http/http.dart' as transport;

import 'urls/hosteday_static_pages.dart';
import 'auth/hosteday_auth.dart';
import 'auth/hosteday_auth_storage.dart';
import 'auth/hosteday_auth_token_provider.dart';
import 'auth/hosteday_token_provider.dart';
import 'config/hosteday_config.dart';
import 'connectivity/hosteday_connectivity.dart';
import 'http/hosteday_http_client.dart';
import 'jobs/hosteday_jobs_client.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'notifications/hosteday_notification_client.dart';
import 'realtime/hosteday_realtime_client.dart';

/// A high-level client for interacting with Hosteday services.
///
/// This client provides:
/// - HTTP API requests.
/// - Authentication access through [auth].
/// - Realtime access through [realtime].
/// - Realtime event publishing helpers.
///
/// Authentication and user API paths are fixed by Hosteday and are managed
/// internally by [HostedayAuth].
class HostedayClient {
  /// The configuration used to connect to Hosteday services.
  final HostedayConfig config;

  /// Optional external token provider supplied during SDK initialization.
  ///
  /// This is used only as a fallback when there is no active Hosteday auth
  /// session stored in [authStorage].
  final HostedayTokenProvider? tokenProvider;

  /// Storage used to persist the authenticated user session.
  final HostedayAuthStorage authStorage;

  /// Token provider used internally by HTTP and realtime clients.
  ///
  /// It reads the active Hosteday auth session first, then falls back to the
  /// externally supplied [tokenProvider] when available.
  late final HostedayTokenProvider effectiveTokenProvider;

  /// The HTTP client responsible for executing API requests.
  late final HostedayHttpClient http;

  /// The connectivity service responsible for monitoring network and backend reachability.
  late final HostedayConnectivity connectivity;

  /// The realtime client responsible for managing live connections.
  late final HostedayRealtimeClient realtime;

  /// The notification client responsible for device tokens and push messages.
  late final HostedayNotificationClient notifications;

  /// The jobs client responsible for smart background tasks and queues.
  late final HostedayJobsClient jobs;

  /// Feature flags and plan entitlements.
  late final HostedayFeatures features;

  /// Authentication service for the current Hosteday application.
  late final HostedayAuth auth;

  /// Creates a [HostedayClient] using the provided [config].
  ///
  /// [authStorage] defaults to in-memory storage. For production apps, pass
  /// a secure storage implementation.
  HostedayClient({
    required this.config,
    this.tokenProvider,
    transport.Client? httpClient,
    HostedayAuthStorage? authStorage,
    HostedayFeatures? features,
    InternetConnection? internetConnection,
    HostedayConnectivity? connectivity,
  }) : authStorage = authStorage ?? MemoryHostedayAuthStorage() {
    this.features = features ?? config.features;
    final authTokenProvider = HostedayAuthTokenProvider(
      storage: this.authStorage,
    );

    effectiveTokenProvider = HostedayCombinedTokenProvider(
      primary: authTokenProvider,
      fallback: tokenProvider,
    );

    this.connectivity = connectivity ??
        HostedayConnectivity(
          config: config,
          checker: internetConnection,
        );

    http = HostedayHttpClient(
      client: httpClient,
      config: config,
      tokenProvider: effectiveTokenProvider,
      onNetworkResult: (isOnline) {
        if (isOnline) {
          this.connectivity.reportSuccess();
        } else {
          this.connectivity.reportFailure();
        }
      },
    );

    realtime = HostedayRealtimeClient(
      config: config,
      tokenProvider: effectiveTokenProvider,
      authStorage: this.authStorage,
      headersCallback: () async {
        final sessionToken = auth.currentSession?.accessToken.trim();
        final currentToken = (sessionToken != null && sessionToken.isNotEmpty)
            ? sessionToken
            : (await effectiveTokenProvider.getToken() ??
                await this.authStorage.read(HostedayAuthStorageKeys.accessToken));
        final cleanToken = currentToken?.trim();

        final headers = <String, String>{
          'Accept': 'application/json',
          ...config.defaultHeaders,
        };

        final apiToken = config.apiToken?.trim();
        if (apiToken != null && apiToken.isNotEmpty) {
          headers['X-Api-Token'] = apiToken;
          if (config.apiTokenHeader.isNotEmpty) {
            headers[config.apiTokenHeader] = apiToken;
          }
        }

        if (cleanToken != null && cleanToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $cleanToken';
        }

        return headers;
      },
    );

    notifications = HostedayNotificationClient(
      config: config,
      http: http,
      tokenProvider: effectiveTokenProvider,
    );

    jobs = HostedayJobsClient(
      config: config,
      http: http,
      tokenProvider: effectiveTokenProvider,
    );

    auth = HostedayAuth(
      config: config,
      http: http,
      storage: this.authStorage,
      onSessionCleared: realtime.disconnect,
      onSessionActivated: (user) async {
        final currentToken = notifications.currentToken;
        if (currentToken != null && currentToken.isNotEmpty) {
          try {
            final token = await auth.getAccessToken();
            await notifications.syncDeviceToken(
              token: currentToken,
              accessToken: token,
              deviceId: notifications.currentDeviceId,
              deviceType: notifications.currentDeviceType,
              deviceName: notifications.currentDeviceName,
            );
          } catch (_) {}
        }
        if (config.hasRealtime &&
            config.features.isRealtimeEnabled &&
            !realtime.isConnected) {
          try {
            await realtime.connect();
          } catch (_) {}
        }
      },
      onBeforeSignOut: () async {
        final currentToken = notifications.currentToken;
        if (currentToken != null && currentToken.isNotEmpty) {
          try {
            final token = await auth.getAccessToken();
            await notifications.unregisterDeviceToken(
              token: currentToken,
              deviceId: notifications.currentDeviceId,
              action: 'unlink',
              accessToken: token,
            );
          } catch (_) {}
        }
      },
    );
  }

  /// Root URL of the project, for example `https://max.hosteday.com`.
  String get host => config.host;

  /// Effective REST base URL, normally `$host/api`.
  String get apiBaseUrl => config.apiBaseUrl;

  /// Public pages, for example `client.staticPages['info']`.
  HostedayStaticPages get staticPages => HostedayStaticPages(config.urls);

  /// Resolves a relative public file path; absolute HTTP(S) URLs are preserved.
  String storageUrl(String path) => config.urls.storage(path);

  /// Restores the saved authentication session.
  ///
  /// Call this once during SDK initialization so [auth] can load the stored
  /// session and notify auth state listeners.
  Future<void> initialize() {
    return auth.initialize();
  }

  /// Sends a raw HTTP request to the Hosteday API.
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

  /// Fetches one page, unwrapping the Hosteday pagination envelope.
  ///
  /// [page] overrides any page in [queryParameters] when supplied. Server links
  /// are metadata only; request subsequent pages using this method again.
  Future<HostedayPage> index(
    String path, {
    int? page,
    String? search,
    Map<String, Object?>? filters,
    String? relationField,
    Object? relationValue,
    Map<String, Object?>? queryParameters,
    bool withAuth = false,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    if (page != null && page < 1) {
      throw ArgumentError.value(page, 'page', 'Must be a positive integer.');
    }
    final hostedayResponse = await get(
      path,
      search: search,
      filters: filters,
      relationField: relationField,
      relationValue: relationValue,
      queryParameters: {...?queryParameters, if (page != null) 'page': page},
      withAuth: withAuth,
      headers: headers,
      timeout: timeout,
    );
    return HostedayResponseReader.index(hostedayResponse);
  }

  /// Fetches a record, returning the object inside the Hosteday envelope.
  ///
  /// [id] is appended using the same encoded path segment policy as [get].
  Future<Map<String, dynamic>> show(
    String path, {
    required Object id,
    String? search,
    String? relationField,
    Object? relationValue,
    Map<String, Object?>? queryParameters,
    bool withAuth = false,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final hostedayResponse = await get(
      path,
      id: id,
      search: search,
      relationField: relationField,
      relationValue: relationValue,
      queryParameters: queryParameters,
      withAuth: withAuth,
      headers: headers,
      timeout: timeout,
    );
    return HostedayResponseReader.show(hostedayResponse);
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
    Object? id,
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
    Object? id,
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
    Object? id,
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

  /// Publishes an event to a public Hosteday realtime channel.
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
      withAuth: false,
      body: <String, dynamic>{
        'channel': _normalizePublicChannel(channel),
        'event': event,
        'payload': payload,
      },
    );
  }

  /// Publishes an event to a private Hosteday realtime channel.
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

  /// Publishes an event to a presence Hosteday realtime channel.
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
  /// This disconnects realtime, disposes notifications, auth streams, and closes HTTP.
  Future<void> dispose() async {
    connectivity.dispose();
    notifications.dispose();
    await jobs.dispose();
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
