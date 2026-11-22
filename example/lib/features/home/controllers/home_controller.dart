import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';

enum HomeTab { guide, realtime, settings, profile }

/// Reactive GetX controller for the main shell navigation and tabs.
class HomeController extends GetxController {
  final Rx<HomeTab> currentTab = HomeTab.guide.obs;

  int get selectedIndex => currentTab.value.index;

  void setTabIndex(int index) {
    if (index >= 0 && index < HomeTab.values.length) {
      setTab(HomeTab.values[index]);
    }
  }

  void setTab(HomeTab tab) {
    currentTab.value = tab;
    final targetRoute = switch (tab) {
      HomeTab.guide => AppRoutes.home,
      HomeTab.realtime => AppRoutes.realtime,
      HomeTab.settings => AppRoutes.settings,
      HomeTab.profile => AppRoutes.profile,
    };
    if (Get.currentRoute != targetRoute) {
      Get.offNamed(targetRoute);
    }
  }
}
