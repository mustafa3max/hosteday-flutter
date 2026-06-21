import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../config/demo_hosteday_options.dart';

/// نقطة التهيئة الوحيدة لحزمة HosteDay داخل التطبيق.
abstract final class HosteDayInitializer {
  static Future<void> initialize() {
    return HosteDay.initializeApp(
      options: const <String, Object?>{
        HosteDayOptionKeys.projectDomain: DemoHosteDayOptions.projectDomain,
        HosteDayOptionKeys.apiToken: DemoHosteDayOptions.apiToken,
        HosteDayOptionKeys.realtimeHost: DemoHosteDayOptions.realtimeHost,
        HosteDayOptionKeys.pusherKey: DemoHosteDayOptions.pusherKey,
      },

      /// عند عدم تمرير authStorage سيستخدم الـ SDK تخزيناً مؤقتاً في الذاكرة.
      ///
      /// في الإنتاج مرر HosteDayAuthStorage مبنياً على flutter_secure_storage
      /// حتى تستمر الجلسة بعد إغلاق التطبيق.
    );
  }
}
