import 'package:flutter/foundation.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../hosteday_config.dart';

/// Initializes the Hosteday SDK before the Flutter app starts.
///
/// Uses direct strongly-typed [HostedayConfig] configuration,
/// eliminating any need for manual assets loading or JSON decoding.
class HostedayInitializer {
  const HostedayInitializer._();

  static Future<void> initialize() async {
    debugPrint(
      '[HostedayInitializer] Initializing Hosteday with app "${HosteDayConfig.appName}" '
      'at ${HosteDayConfig.baseUrl}',
    );

    await Hosteday.initializeApp(
      config: const HostedayConfig(
        baseUrl: HosteDayConfig.baseUrl,
        pusherKey: HosteDayConfig.wsKey,
        realtimeHost: HosteDayConfig.wsHost,
        firebaseProjectId: HosteDayConfig.firebaseProjectId,
        notificationsEnabled: HosteDayConfig.pushNotificationsEnabled,
        jobsEnabled: true,
        features: HostedayFeatures({
          'push_notifications': HosteDayConfig.pushNotificationsEnabled,
          'realtime_websockets': HosteDayConfig.realtimeWebsocketsEnabled,
        }),
      ),
      connectRealtime: false,
      jobsEnabled: true,
      authStorage: HostedaySharedPreferencesAuthStorage(),
    );

    debugPrint('[HostedayInitializer] Hosteday initialized successfully.');
  }
}
