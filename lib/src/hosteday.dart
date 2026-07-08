import 'auth/hosteday_auth.dart';
import 'auth/hosteday_auth_storage.dart';
import 'auth/hosteday_token_provider.dart';
import 'config/hosteday_config.dart';
import 'hosteday_client.dart';
import 'http/hosteday_http_client.dart';
import 'realtime/hosteday_realtime_client.dart';

/// Global HosteDay application entry point.
///
/// Initialize the SDK once during application startup using [initializeApp].
/// Afterwards, access the configured client through [client] or [instance].
abstract final class HosteDay {
  HosteDay._();

  static HosteDayClient? _client;
  static HosteDayConfig? _config;
  static Future<HosteDayClient>? _initializing;

  /// Returns whether HosteDay has already been initialized.
  static bool get isInitialized => _client != null;

  /// Returns whether HosteDay is currently initializing.
  static bool get isInitializing => _initializing != null;

  /// Returns the initialized HosteDay client.
  ///
  /// Throws a [StateError] when [initializeApp] has not been called.
  static HosteDayClient get instance {
    final value = _client;

    if (value == null) {
      throw StateError(
        'HosteDay has not been initialized. '
        'Call HosteDay.initializeApp() first.',
      );
    }

    return value;
  }

  /// Alias for [instance].
  static HosteDayClient get client => instance;

  /// Returns the configuration used by the initialized application.
  static HosteDayConfig get config {
    final value = _config;

    if (value == null) {
      throw StateError(
        'HosteDay has not been initialized. '
        'Call HosteDay.initializeApp() first.',
      );
    }

    return value;
  }

  /// Returns the authentication service for the initialized HosteDay app.
  static HosteDayAuth get auth => client.auth;

  /// Returns the HTTP client for the initialized HosteDay app.
  static HosteDayHttpClient get http => client.http;

  /// Returns the realtime client for the initialized HosteDay app.
  static HosteDayRealtimeClient get realtime => client.realtime;

  /// Initializes the HosteDay SDK.
  ///
  /// [options] must include the HosteDay project domain.
  ///
  /// [authStorage] is used to persist and restore the authenticated session.
  /// When omitted, the SDK uses temporary in-memory storage.
  ///
  /// Set [connectRealtime] to true only when the app should open the realtime
  /// connection immediately during startup.
  static Future<HosteDayClient> initializeApp({
    required Map<String, Object?> options,
    HosteDayTokenProvider? tokenProvider,
    HosteDayAuthStorage? authStorage,
    bool connectRealtime = false,
  }) {
    final currentClient = _client;

    if (currentClient != null) {
      throw StateError(
        'HosteDay is already initialized. '
        'Use HosteDay.client or call HosteDay.dispose() first.',
      );
    }

    final currentInitialization = _initializing;

    if (currentInitialization != null) {
      return currentInitialization;
    }

    final initialization = _initializeApp(
      options: options,
      tokenProvider: tokenProvider,
      authStorage: authStorage,
      connectRealtime: connectRealtime,
    );

    _initializing = initialization;

    return initialization.whenComplete(() {
      _initializing = null;
    });
  }

  static Future<HosteDayClient> _initializeApp({
    required Map<String, Object?> options,
    HosteDayTokenProvider? tokenProvider,
    HosteDayAuthStorage? authStorage,
    bool connectRealtime = false,
  }) async {
    final appConfig = HosteDayConfig.fromOptions(options);

    final appClient = HosteDayClient(
      config: appConfig,
      tokenProvider: tokenProvider,
      authStorage: authStorage,
    );

    try {
      await appClient.initialize();

      if (connectRealtime) {
        await appClient.realtime.connect();
      }

      _config = appConfig;
      _client = appClient;

      return appClient;
    } catch (_) {
      await appClient.dispose();
      rethrow;
    }
  }

  /// Connects to the configured realtime service.
  static Future<void> connectRealtime() {
    return realtime.connect();
  }

  /// Disconnects from the configured realtime service.
  static Future<void> disconnectRealtime() {
    return realtime.disconnect();
  }

  /// Releases all HTTP, auth, and realtime resources.
  ///
  /// After calling this method, [initializeApp] may be called again.
  static Future<void> dispose() async {
    final currentClient = _client;

    _client = null;
    _config = null;
    _initializing = null;

    if (currentClient != null) {
      await currentClient.dispose();
    }
  }
}

/// Backward-compatible alias for the old Hosteday API.
///
/// Deprecated: use [HosteDay] in all new code.
@Deprecated(
  'Use HosteDay instead. '
  'This compatibility class will be removed in a future major version.',
)
abstract final class Hosteday {
  Hosteday._();

  static bool get isInitialized => HosteDay.isInitialized;

  static bool get isInitializing => HosteDay.isInitializing;

  static HosteDayClient get instance => HosteDay.instance;

  static HosteDayClient get client => HosteDay.client;

  static HosteDayConfig get config => HosteDay.config;

  static HosteDayAuth get auth => HosteDay.auth;

  static HosteDayHttpClient get http => HosteDay.http;

  static HosteDayRealtimeClient get realtime => HosteDay.realtime;

  static Future<HosteDayClient> initializeApp({
    required Map<String, Object?> options,
    HosteDayTokenProvider? tokenProvider,
    HosteDayAuthStorage? authStorage,
    bool connectRealtime = false,
  }) {
    return HosteDay.initializeApp(
      options: options,
      tokenProvider: tokenProvider,
      authStorage: authStorage,
      connectRealtime: connectRealtime,
    );
  }

  static Future<void> connectRealtime() {
    return HosteDay.connectRealtime();
  }

  static Future<void> disconnectRealtime() {
    return HosteDay.disconnectRealtime();
  }

  static Future<void> dispose() {
    return HosteDay.dispose();
  }
}
