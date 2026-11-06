import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../config/example_environment.dart';
import '../../hosteday_config.dart';

/// Initializes the Hosteday SDK before the Flutter app starts.
///
/// Keep SDK setup in one place so examples and production apps can understand
/// only the project domain is required. Tokens and realtime are optional.
class HostedayInitializer {
  const HostedayInitializer._();

  static Future<void> initialize() async {
    await Hosteday.initializeApp(
      options: ExampleEnvironment.hostedayOptions,
      connectRealtime: HosteDayConfig.realtimeWebsocketsEnabled && HosteDayConfig.wsKey.isNotEmpty,
      authStorage: HostedaySharedPreferencesAuthStorage(),
    );
  }
}
