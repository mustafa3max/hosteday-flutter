import 'package:get/get.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/user/controllers/user_controller.dart';
import '../localization/localization_controller.dart';
import '../notifications/push_notification_service.dart';
import '../theme/theme_controller.dart';

/// Core application dependencies initialized before the UI loads.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<LocalizationController>(LocalizationController(), permanent: true);
    Get.put<ThemeController>(ThemeController(), permanent: true);
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<HomeController>(HomeController(), permanent: true);
    Get.put<SettingsController>(SettingsController(), permanent: true);
    Get.lazyPut<UserController>(() => UserController(), fenix: true);
    final pushService = Get.put<PushNotificationService>(
      PushNotificationService(),
      permanent: true,
    );
    // Initialize push notifications asynchronously in background
    pushService.initialize();
  }
}
