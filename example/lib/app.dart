import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import 'core/bindings/initial_binding.dart';
import 'core/localization/app_translations.dart';
import 'core/localization/localization_controller.dart';
import 'core/routes/app_pages.dart';
import 'core/theme/theme_controller.dart';

/// Root application widget powered by GetX with multi-theme and localization support.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>()
        : Get.put(ThemeController(), permanent: true);

    final localizationController = Get.isRegistered<LocalizationController>()
        ? Get.find<LocalizationController>()
        : Get.put(LocalizationController(), permanent: true);

    return Obx(() {
      final theme = themeController.currentTheme;
      return GetMaterialApp(
        title: 'app_title'.tr,
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: theme,
        themeMode: themeController.isDark ? ThemeMode.dark : ThemeMode.light,
        translations: AppTranslations(),
        locale: localizationController.currentLocale.value,
        fallbackLocale: const Locale('en', 'US'),
        initialBinding: InitialBinding(),
        initialRoute: AppPages.initial,
        getPages: AppPages.pages,
        defaultTransition: Transition.fadeIn,
        builder: (context, child) =>
            HostedayConnectivityBanner(child: child ?? const SizedBox.shrink()),
      );
    });
  }
}
