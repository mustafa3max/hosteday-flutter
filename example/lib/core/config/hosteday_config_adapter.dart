import '../../hosteday_config.dart';

/// Adapter providing options mapping and helper methods for [HosteDayConfig].
///
/// Keeps `lib/hosteday_config.dart` pure and strictly aligned with the CLI output schema.
abstract final class HosteDayConfigAdapter {
  /// Converts [HosteDayConfig] constants into an options map accepted by `Hosteday.initializeApp`.
  static Map<String, dynamic> toOptions({
    Map<String, dynamic>? overrides,
  }) {
    final scheme = HosteDayConfig.wsScheme.trim().toLowerCase();
    final effectiveWsScheme = (scheme == 'https' || scheme == 'wss') ? 'wss' : 'ws';

    return <String, dynamic>{
      'project_domain': HosteDayConfig.baseUrl,
      'base_url': HosteDayConfig.baseUrl,
      'project_name': HosteDayConfig.appName,
      'slug': HosteDayConfig.slug,
      'environment_id': HosteDayConfig.environmentId,
      'realtime_app_key': HosteDayConfig.wsKey,
      'realtime_host': HosteDayConfig.wsHost,
      'realtime_port': HosteDayConfig.wsPort,
      'realtime_scheme': effectiveWsScheme,
      'firebase_project_id': HosteDayConfig.firebaseProjectId,
      'notifications_enabled': HosteDayConfig.pushNotificationsEnabled,
      'features': {
        'push_notifications': HosteDayConfig.pushNotificationsEnabled,
        'realtime_websockets': HosteDayConfig.realtimeWebsocketsEnabled,
      },
      'register_device_token_path': HosteDayConfig.deviceRegisterEndpoint,
      'unregister_device_token_path': HosteDayConfig.deviceUnregisterEndpoint,
      ...?overrides,
    };
  }
}

