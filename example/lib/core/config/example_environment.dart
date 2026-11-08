import '../../hosteday_config.dart';
import 'hosteday_config_adapter.dart';

/// Centralized configuration provider for the HosteDay starter application.
///
/// Automatically bound to the official HosteDay CLI configuration file
/// generated at `lib/hosteday_config.dart`.
class ExampleEnvironment {
  const ExampleEnvironment._();

  static String get appName => HosteDayConfig.appName;
  static String get slug => HosteDayConfig.slug;
  static String get environmentId => HosteDayConfig.environmentId;
  static String get projectDomain => HosteDayConfig.baseUrl;
  static String get projectAccessToken => '';

  static String get realtimeAppKey => HosteDayConfig.wsKey;
  static String get realtimeHost => HosteDayConfig.wsHost;
  static String get realtimeScheme =>
      (HosteDayConfig.wsScheme == 'https' || HosteDayConfig.wsScheme == 'wss')
          ? 'wss'
          : 'ws';
  static int get realtimePort => HosteDayConfig.wsPort;

  // ---------------------------------------------------------------------------
  // Push Notifications (FCM v1 / Web Push) & Firebase Credentials
  // ---------------------------------------------------------------------------
  static String? get firebaseProjectId => HosteDayConfig.firebaseProjectId;
  static bool get notificationsEnabled =>
      HosteDayConfig.pushNotificationsEnabled;
  static bool get realtimeWebsocketsEnabled =>
      HosteDayConfig.realtimeWebsocketsEnabled;
  static const bool jobsEnabled = true;

  /// Creates options map for `Hosteday.initializeApp` from `HosteDayConfig`.
  static Map<String, dynamic> createHosteDayOptions({
    Map<String, dynamic>? firebaseConfig,
    Map<String, dynamic>? features,
  }) {
    return HosteDayConfigAdapter.toOptions(
      overrides: {
        ...?firebaseConfig,
        'features': ?features,
        'jobs_enabled': jobsEnabled,
        'jobs_path': '/api/jobs',
      },
    );
  }

  /// Default options backward compatibility getter.
  static Map<String, dynamic> get hosteDayOptions => createHosteDayOptions();
}
