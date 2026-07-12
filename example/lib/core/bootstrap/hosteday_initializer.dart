import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../config/example_environment.dart';

/// Initializes the HosteDay SDK before the Flutter app starts.
///
/// Keep SDK setup in one place so examples and production apps can understand
/// which values are required: project domain, project access token, and realtime
/// connection options.
class HosteDayInitializer {
  const HosteDayInitializer._();

  static Future<void> initialize() async {
    await HosteDay.initializeApp(
      options: ExampleEnvironment.hosteDayOptions,
      connectRealtime: false,
      authStorage: HosteDaySharedPreferencesAuthStorage(),
    );
  }
}
