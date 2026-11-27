import 'package:flutter/foundation.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

/// Initializes the Hosteday SDK before the Flutter app starts.
///
/// Reads configuration exclusively from `assets/hosteday_config.json` inside
/// the `hosteday_flutter` package.
class HostedayInitializer {
  const HostedayInitializer._();

  static Future<void> initialize() async {
    await Hosteday.initializeApp();
    debugPrint(
      '[HostedayInitializer] Hosteday initialized for ${Hosteday.config.baseUrl}.',
    );
  }
}
