/// Compile-time configuration for the example app.
///
/// Run with:
///
/// ```bash
/// flutter run \
///   --dart-define=HOSTEDAY_PROJECT_DOMAIN=https://your-project.hosteday.com \
///   --dart-define=HOSTEDAY_PROJECT_ACCESS_TOKEN=your_public_project_token \
///   --dart-define=HOSTEDAY_REALTIME_APP_KEY=your_realtime_app_key \
///   --dart-define=HOSTEDAY_REALTIME_HOST=your-project.hosteday.com
/// ```
///
/// The example intentionally avoids hardcoding real secrets. Values passed with
/// `--dart-define` are still client-side values and must be treated as public
/// application configuration, not private server secrets.
class ExampleEnvironment {
  const ExampleEnvironment._();

  static const String projectDomain = String.fromEnvironment(
    'HOSTEDAY_PROJECT_DOMAIN',
    defaultValue: 'https://free-3.hosteday.com',
  );

  static const String projectAccessToken = String.fromEnvironment(
    'HOSTEDAY_PROJECT_ACCESS_TOKEN',
    defaultValue: '',
  );

  static const String realtimeAppKey = String.fromEnvironment(
    'HOSTEDAY_REALTIME_APP_KEY',
    defaultValue: 'YOUR_REALTIME_APP_KEY',
  );

  static const String realtimeHost = String.fromEnvironment(
    'HOSTEDAY_REALTIME_HOST',
    defaultValue: 'project.hosteday.com',
  );

  static const String realtimeScheme = String.fromEnvironment(
    'HOSTEDAY_REALTIME_SCHEME',
    defaultValue: 'wss',
  );

  static const int realtimePort = int.fromEnvironment(
    'HOSTEDAY_REALTIME_PORT',
    defaultValue: 443,
  );

  /// Options passed to `HosteDay.initializeApp`.
  ///
  /// The map includes friendly names and backward-compatible keys. This makes
  /// the example easier to understand while still working with SDK versions
  /// that use older option names internally.
  static const Map<String, dynamic> hosteDayOptions = <String, dynamic>{
    'project_domain': projectDomain,

    // Public project/application token. This is not the authenticated user token.
    'project_access_token': projectAccessToken,
    'api_token': projectAccessToken,
    'X-Api-Token': projectAccessToken,

    // Realtime application key. Older SDKs may still read `pusher_key`.
    'realtime_app_key': realtimeAppKey,
    'pusher_key': realtimeAppKey,

    'realtime_host': realtimeHost,
    'realtime_scheme': realtimeScheme,
    'realtime_port': realtimePort,
  };
}
