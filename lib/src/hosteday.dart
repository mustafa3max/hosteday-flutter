import 'dart:convert';

import 'package:flutter/services.dart';

import 'auth/hosteday_auth.dart';
import 'auth/hosteday_auth_storage.dart';
import 'auth/hosteday_token_provider.dart';
import 'config/hosteday_config.dart';
import 'config/hosteday_option_keys.dart';
import 'connectivity/hosteday_connectivity.dart';
import 'exceptions/hosteday_exception.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'features/hosteday_features.dart';
import 'hosteday_client.dart';
import 'http/hosteday_http_client.dart';
import 'jobs/hosteday_jobs_client.dart';
import 'notifications/hosteday_notification_client.dart';
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

  /// The sole official asset path for Hosteday runtime configuration.
  static const String configAssetPath = 'assets/hosteday_config.json';

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

  /// Returns the push notification client for the initialized Hosteday app.
  static HostedayNotificationClient get notifications => client.notifications;

  /// Returns the smart background jobs client for the initialized Hosteday app.
  static HostedayJobsClient get jobs => client.jobs;

  /// Returns the feature flags and plan entitlements for the initialized app.
  static HostedayFeatures get features => client.features;

  /// Returns the connectivity monitoring service for the initialized app.
  static HostedayConnectivity get connectivity => client.connectivity;

  /// Returns whether the device currently has connectivity to Hosteday services.
  static bool get isOnline => client.connectivity.isConnected;

  /// Initializes the Hosteday SDK exclusively from `assets/hosteday_config.json`.
  ///
  /// Place the `hosteday_config.json` file downloaded from your Hosteday
  /// dashboard at `assets/hosteday_config.json` and register it under
  /// `flutter.assets` in `pubspec.yaml`.
  ///
  /// [authStorage] is used to persist and restore the authenticated session.
  /// When omitted, the SDK uses temporary in-memory storage.
  ///
  /// Set [connectRealtime] to true only when the app should open the realtime
  /// connection immediately during startup.
  static Future<HostedayClient> initializeApp({
    AssetBundle? bundle,
    HostedayTokenProvider? tokenProvider,
    HostedayAuthStorage? authStorage,
    bool connectRealtime = true,
    InternetConnection? internetConnection,
    HostedayConnectivity? connectivity,
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
      bundle: bundle,
      tokenProvider: tokenProvider,
      authStorage: authStorage,
      connectRealtime: connectRealtime,
      internetConnection: internetConnection,
      connectivity: connectivity,
    );

    _initializing = initialization;

    return initialization.whenComplete(() {
      _initializing = null;
    });
  }

  static Future<HostedayClient> _initializeApp({
    AssetBundle? bundle,
    HostedayTokenProvider? tokenProvider,
    HostedayAuthStorage? authStorage,
    bool connectRealtime = true,
    InternetConnection? internetConnection,
    HostedayConnectivity? connectivity,
  }) async {
    final String rawJson;
    try {
      rawJson = await (bundle ?? rootBundle).loadString(configAssetPath);
    } catch (error) {
      throw HostedayException(
        'Missing configuration file "$configAssetPath". '
        'Please download hosteday_config.json from your Hosteday dashboard, '
        'place it at "$configAssetPath", and register it under flutter.assets in pubspec.yaml.',
        error: error,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(rawJson);
    } catch (error) {
      throw HostedayException(
        'Invalid JSON in "$configAssetPath". '
        'Please download a valid hosteday_config.json from your Hosteday dashboard '
        'and place it at "$configAssetPath".',
        error: error,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const HostedayException(
        'Invalid configuration format in "$configAssetPath": expected a JSON object. '
        'Please download a valid hosteday_config.json from your Hosteday dashboard '
        'and place it at "$configAssetPath".',
      );
    }

    final effectiveOptions = <String, Object?>{
      HostedayOptionKeys.jobsPath: '/api/jobs',
      ...decoded,
    };

    final HostedayConfig appConfig;
    try {
      appConfig = HostedayConfig.fromOptions(effectiveOptions);
    } on ArgumentError catch (error) {
      throw HostedayException(
        'Invalid or incomplete configuration in "$configAssetPath": ${error.message ?? error}. '
        'Please download a valid hosteday_config.json from your Hosteday dashboard '
        'and place it at "$configAssetPath".',
        error: error,
      );
    }

    final appClient = HostedayClient(
      config: appConfig,
      tokenProvider: tokenProvider,
      authStorage: authStorage,
      internetConnection: internetConnection,
      connectivity: connectivity,
    );

    try {
      await appClient.initialize();

      if (connectRealtime &&
          appConfig.hasRealtime &&
          appConfig.features.isRealtimeEnabled) {
        try {
          await appClient.realtime.connect();
        } catch (_) {
          // Realtime errors are surfaced via Hosteday.realtime.onError
          // without blocking application startup.
        }
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
