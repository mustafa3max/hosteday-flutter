import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/bindings/initial_binding.dart';
import 'core/localization/app_translations.dart';
import 'core/localization/localization_controller.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/theme_controller.dart';
import 'features/home/controllers/home_controller.dart';

/// Root application widget powered by GetX with multi-theme and localization support.
class HostedayExampleApp extends StatelessWidget {
  const HostedayExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>()
        : Get.put(ThemeController(), permanent: true);

    final localizationController = Get.isRegistered<LocalizationController>()
        ? Get.find<LocalizationController>()
        : Get.put(LocalizationController(), permanent: true);

    return Obx(() {
      return GetMaterialApp(
        title: 'app_title'.tr,
        debugShowCheckedModeBanner: false,
        theme: themeController.currentTheme,
        translations: AppTranslations(),
        locale: localizationController.currentLocale.value,
        fallbackLocale: const Locale('en', 'US'),
        initialBinding: InitialBinding(),
        initialRoute: AppPages.initial,
        getPages: AppPages.pages,
        defaultTransition: Transition.fadeIn,
        routingCallback: (routing) {
          if (routing != null && Get.isRegistered<HomeController>()) {
            final homeController = Get.find<HomeController>();
            switch (routing.current) {
              case AppRoutes.home:
                if (homeController.currentTab.value != HomeTab.example) {
                  homeController.currentTab.value = HomeTab.example;
                }
                break;
              case AppRoutes.realtime:
                if (homeController.currentTab.value != HomeTab.realtime) {
                  homeController.currentTab.value = HomeTab.realtime;
                }
                break;
              case AppRoutes.notifications:
                if (homeController.currentTab.value != HomeTab.notifications) {
                  homeController.currentTab.value = HomeTab.notifications;
                }
                break;
              case AppRoutes.profile:
                if (homeController.currentTab.value != HomeTab.profile) {
                  homeController.currentTab.value = HomeTab.profile;
                }
                break;
            }
          }
        },
      );
    });
  }
}
