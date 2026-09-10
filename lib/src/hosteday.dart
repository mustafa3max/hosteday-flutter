import 'dart:convert';

import 'package:flutter/services.dart';

import 'auth/hosteday_auth.dart';
import 'auth/hosteday_auth_storage.dart';
import 'auth/hosteday_token_provider.dart';
import 'config/hosteday_config.dart';
import 'exceptions/hosteday_exception.dart';
import 'hosteday_client.dart';
import 'http/hosteday_http_client.dart';
import 'realtime/hosteday_realtime_client.dart';

/// Global Hosteday application entry point.
///
/// Initialize the SDK once during application startup using [initializeApp].
/// Afterwards, access the configured client through [client] or [instance].
abstract final class Hosteday {
  Hosteday._();

  static HostedayClient? _client;
  static HostedayConfig? _config;
  static Future<HostedayClient>? _initializing;

  /// Returns whether Hosteday has already been initialized.
  static bool get isInitialized => _client != null;

  /// Returns whether Hosteday is currently initializing.
  static bool get isInitializing => _initializing != null;

  /// Returns the initialized Hosteday client.
  ///
  /// Throws a [StateError] when [initializeApp] has not been called.
  static HostedayClient get instance {
    final value = _client;

    if (value == null) {
      throw StateError(
        'Hosteday has not been initialized. '
        'Call Hosteday.initializeApp() first.',
      );
    }

    return value;
  }

  /// Alias for [instance].
  static HostedayClient get client => instance;

  /// Returns the configuration used by the initialized application.
  static HostedayConfig get config {
    final value = _config;

    if (value == null) {
      throw StateError(
        'Hosteday has not been initialized. '
        'Call Hosteday.initializeApp() first.',
      );
    }

    return value;
  }

  /// Returns the authentication service for the initialized Hosteday app.
  static HostedayAuth get auth => client.auth;

  /// Returns the HTTP client for the initialized Hosteday app.
  static HostedayHttpClient get http => client.http;

  /// Returns the realtime client for the initialized Hosteday app.
  static HostedayRealtimeClient get realtime => client.realtime;

  /// Initializes the Hosteday SDK.
  ///
  /// [options] must include the Hosteday project domain.
  ///
  /// [authStorage] is used to persist and restore the authenticated session.
  /// When omitted, the SDK uses temporary in-memory storage.
  ///
  /// Set [connectRealtime] to true only when the app should open the realtime
  /// connection immediately during startup.
  static Future<HostedayClient> initializeApp({
    required Map<String, Object?> options,
    HostedayTokenProvider? tokenProvider,
    HostedayAuthStorage? authStorage,
    bool connectRealtime = false,
  }) {
    final currentClient = _client;

    if (currentClient != null) {
      throw StateError(
        'Hosteday is already initialized. '
        'Use Hosteday.client or call Hosteday.dispose() first.',
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

  /// Initializes from the generated application's bundled runtime JSON.
  /// Declare [assetPath] in the application's pubspec assets section.
  /// Explicit [overrides] win over asset values; null optional values are valid.
  static Future<HostedayClient> initializeFromAsset({
    String assetPath = 'assets/config/hosteday.json',
    Map<String, Object?> overrides = const {},
    AssetBundle? bundle,
    HostedayTokenProvider? tokenProvider,
    HostedayAuthStorage? authStorage,
    bool connectRealtime = false,
  }) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(await (bundle ?? rootBundle).loadString(assetPath));
    } catch (error) {
      throw HostedayException(
          'Unable to read runtime config "$assetPath": $error',
          error: error);
    }
    if (decoded is! Map<String, dynamic>) {
      throw const HostedayException('Runtime config must be a JSON object.');
    }
    return initializeApp(
      options: {...decoded, ...overrides},
      tokenProvider: tokenProvider,
      authStorage: authStorage,
      connectRealtime: connectRealtime,
    );
  }

  static Future<HostedayClient> _initializeApp({
    required Map<String, Object?> options,
    HostedayTokenProvider? tokenProvider,
    HostedayAuthStorage? authStorage,
    bool connectRealtime = false,
  }) async {
    final appConfig = HostedayConfig.fromOptions(options);

    final appClient = HostedayClient(
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

/// Backward-compatible alias for the old HosteDay API.
///
/// Deprecated: use [Hosteday] in all new code.
@Deprecated(
  'Use Hosteday instead. '
  'This compatibility class will be removed in a future major version.',
)
abstract final class HosteDay {
  HosteDay._();

  static bool get isInitialized => Hosteday.isInitialized;

  static bool get isInitializing => Hosteday.isInitializing;

  static HostedayClient get instance => Hosteday.instance;

  static HostedayClient get client => Hosteday.client;

  static HostedayConfig get config => Hosteday.config;

  static HostedayAuth get auth => Hosteday.auth;

  static HostedayHttpClient get http => Hosteday.http;

  static HostedayRealtimeClient get realtime => Hosteday.realtime;

  static Future<HostedayClient> initializeApp({
    required Map<String, Object?> options,
    HostedayTokenProvider? tokenProvider,
    HostedayAuthStorage? authStorage,
    bool connectRealtime = false,
  }) {
    return Hosteday.initializeApp(
      options: options,
      tokenProvider: tokenProvider,
      authStorage: authStorage,
      connectRealtime: connectRealtime,
    );
  }

  static Future<void> connectRealtime() {
    return Hosteday.connectRealtime();
  }

  static Future<void> disconnectRealtime() {
    return Hosteday.disconnectRealtime();
  }

  static Future<void> dispose() {
    return Hosteday.dispose();
  }
}
