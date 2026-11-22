import '../../hosteday_config.dart';

/// Adapter providing options mapping for [HosteDayConfig].
///
/// Keeps `lib/hosteday_config.dart` pure and strictly aligned with the CLI output schema.
abstract final class HosteDayConfigAdapter {
  /// Converts [HosteDayConfig] constants into an options map accepted by `Hosteday.initializeApp`.
  static Map<String, dynamic> toOptions({Map<String, dynamic>? overrides}) {
    return <String, dynamic>{
      'project_domain': HosteDayConfig.baseUrl,
      'base_url': HosteDayConfig.baseUrl,
      'project_name': HosteDayConfig.appName,
      'slug': HosteDayConfig.slug,
      'environment_id': HosteDayConfig.environmentId,
      'realtime_app_key': HosteDayConfig.wsKey,
      'realtime_host': HosteDayConfig.wsHost,
      'firebase_project_id': HosteDayConfig.firebaseProjectId,
      'notifications_enabled': HosteDayConfig.pushNotificationsEnabled,
      'jobs_enabled': true,
      'features': {
        'push_notifications': HosteDayConfig.pushNotificationsEnabled,
        'realtime_websockets': HosteDayConfig.realtimeWebsocketsEnabled,
      },
      ...?overrides,
    };
  }
}
