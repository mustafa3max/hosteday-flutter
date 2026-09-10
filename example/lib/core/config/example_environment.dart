import 'package:hosteday_flutter/hosteday_flutter.dart';

/// Public client configuration supplied with --dart-define.
class ExampleEnvironment {
  const ExampleEnvironment._();
  static const projectDomain = String.fromEnvironment(
    'HOSTEDAY_PROJECT_DOMAIN',
    defaultValue: 'max.hosteday.com',
  );
  static const projectAccessToken = String.fromEnvironment(
    'HOSTEDAY_PROJECT_API_KEY',
  );
  static const realtimeAppKey = String.fromEnvironment(
    'HOSTEDAY_REALTIME_APP_KEY',
  );
  static const realtimeHost = String.fromEnvironment('HOSTEDAY_REALTIME_HOST');
  static const realtimeScheme = String.fromEnvironment(
    'HOSTEDAY_REALTIME_SCHEME',
    defaultValue: 'wss',
  );
  static const realtimePort = int.fromEnvironment(
    'HOSTEDAY_REALTIME_PORT',
    defaultValue: 443,
  );
  static const Map<String, Object?> hostedayOptions = {
    HostedayOptionKeys.projectDomain: projectDomain,
    HostedayOptionKeys.projectApiKey: projectAccessToken,
    HostedayOptionKeys.realtimeAppKey: realtimeAppKey,
    HostedayOptionKeys.realtimeHost: realtimeHost,
    HostedayOptionKeys.realtimeScheme: realtimeScheme,
    HostedayOptionKeys.realtimePort: realtimePort,
  };
}
