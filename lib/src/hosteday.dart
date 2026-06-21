import 'auth/hosteday_auth.dart';
import 'auth/hosteday_auth_storage.dart';
import 'auth/hosteday_token_provider.dart';
import 'config/hosteday_config.dart';
import 'hosteday_client.dart';

/// Global HosteDay application entry point.
///
/// Initialize the SDK once during application startup using [initializeApp].
/// Afterwards, access the configured client through [client] or [instance].
abstract final class HosteDay {
  HosteDay._();

  static HosteDayClient? _client;
  static HosteDayConfig? _config;

  /// Returns the authentication service for the initialized HosteDay app.
  static HosteDayAuth get auth => client.auth;

  /// Returns whether HosteDay has already been initialized.
  static bool get isInitialized => _client != null;

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

  /// Initializes the HosteDay SDK.
  ///
  /// [authStorage] is used to persist and restore the authenticated session.
  /// When omitted, the SDK uses temporary in-memory storage.
  static Future<HosteDayClient> initializeApp({
    required Map<String, Object?> options,
    HosteDayTokenProvider? tokenProvider,
    HosteDayAuthStorage? authStorage,
    bool connectRealtime = false,
  }) async {
    if (_client != null) {
      throw StateError(
        'HosteDay is already initialized. '
        'Use HosteDay.client or call HosteDay.dispose() first.',
      );
    }

    final appConfig = HosteDayConfig.fromOptions(options);

    final appClient = HosteDayClient(
      config: appConfig,
      tokenProvider: tokenProvider,
      authStorage: authStorage,
    );

    _config = appConfig;
    _client = appClient;

    try {
      await appClient.initialize();

      if (connectRealtime) {
        await appClient.realtime.connect();
      }

      return appClient;
    } catch (_) {
      _client = null;
      _config = null;

      await appClient.dispose();

      rethrow;
    }
  }

  /// Connects to the configured realtime service.
  static Future<void> connectRealtime() {
    return client.realtime.connect();
  }

  /// Releases all HTTP, auth, and realtime resources.
  ///
  /// After calling this method, [initializeApp] may be called again.
  static Future<void> dispose() async {
    final currentClient = _client;

    _client = null;
    _config = null;

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

  static HosteDayClient get instance => HosteDay.instance;

  static HosteDayClient get client => HosteDay.client;

  static HosteDayConfig get config => HosteDay.config;

  static HosteDayAuth get auth => HosteDay.auth;

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

  static Future<void> dispose() {
    return HosteDay.dispose();
  }
}
