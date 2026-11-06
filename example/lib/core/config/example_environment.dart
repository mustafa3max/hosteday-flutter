import 'package:hosteday_flutter/hosteday_flutter.dart';
import '../../hosteday_config.dart';

/// Public client configuration supplied with --dart-define or HosteDayConfig.
class ExampleEnvironment {
  const ExampleEnvironment._();

  static const _envDomain = String.fromEnvironment('HOSTEDAY_PROJECT_DOMAIN');
  static String get projectDomain {
    if (_envDomain.isNotEmpty) return _envDomain;
    if (HosteDayConfig.slug.isNotEmpty && HosteDayConfig.slug != 'your-project') {
      return '${HosteDayConfig.slug}.hosteday.com';
    }
    return HosteDayConfig.slug.isNotEmpty
        ? '${HosteDayConfig.slug}.hosteday.com'
        : 'your-project.hosteday.com';
  }

  static const _envToken = String.fromEnvironment('HOSTEDAY_PROJECT_API_KEY');
  static String get projectAccessToken => _envToken;

  static const _envRealtimeKey = String.fromEnvironment('HOSTEDAY_REALTIME_APP_KEY');
  static String get realtimeAppKey =>
      _envRealtimeKey.isNotEmpty ? _envRealtimeKey : HosteDayConfig.wsKey;

  static const _envRealtimeHost = String.fromEnvironment('HOSTEDAY_REALTIME_HOST');
  static String get realtimeHost =>
      _envRealtimeHost.isNotEmpty ? _envRealtimeHost : HosteDayConfig.wsHost;

  static const _envRealtimeScheme = String.fromEnvironment('HOSTEDAY_REALTIME_SCHEME');
  static String get realtimeScheme =>
      _envRealtimeScheme.isNotEmpty ? _envRealtimeScheme : HosteDayConfig.wsScheme;

  static const _envRealtimePort = int.fromEnvironment('HOSTEDAY_REALTIME_PORT', defaultValue: 0);
  static int get realtimePort =>
      _envRealtimePort != 0 ? _envRealtimePort : HosteDayConfig.wsPort;

  static Map<String, Object?> get hostedayOptions => {
    HostedayOptionKeys.projectDomain: projectDomain,
    HostedayOptionKeys.projectApiKey: projectAccessToken,
    HostedayOptionKeys.realtimeAppKey: realtimeAppKey,
    HostedayOptionKeys.realtimeHost: realtimeHost,
    HostedayOptionKeys.realtimeScheme: realtimeScheme,
    HostedayOptionKeys.realtimePort: realtimePort,
  };
}
