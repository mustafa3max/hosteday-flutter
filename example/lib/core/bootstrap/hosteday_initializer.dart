import 'package:flutter/foundation.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../hosteday_config.dart';
import '../config/hosteday_config_adapter.dart';

/// Initializes the Hosteday SDK before the Flutter app starts.
///
/// Uses the strongly-typed Dart configuration defined in `lib/hosteday_config.dart`,
/// eliminating any need for manual assets loading or JSON decoding.
class HostedayInitializer {
  const HostedayInitializer._();

  static Future<void> initialize() async {
    debugPrint(
      '[HostedayInitializer] Initializing Hosteday with app "${HosteDayConfig.appName}" '
      'at ${HosteDayConfig.baseUrl}',
    );

    await Hosteday.initializeApp(
      options: HosteDayConfigAdapter.toOptions(
        overrides: const {
          'jobs_enabled': true,
          'jobs_path': '/api/jobs',
        },
      ),
      connectRealtime: false,
      authStorage: HostedaySharedPreferencesAuthStorage(),
    );

    debugPrint('[HostedayInitializer] Hosteday initialized successfully.');
  }
}
