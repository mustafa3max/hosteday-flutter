import 'package:get/get.dart';

import '../../../../core/localization/localization_controller.dart';
import '../presentation/pages/example_guide_page.dart';

/// GetX controller for Example Guide tab state, hooked with app-wide LocalizationController.
class ExampleGuideController extends GetxController {
  final Rx<GuideCategory> selectedCategory = GuideCategory.all.obs;

  bool get isArabic => Get.isRegistered<LocalizationController>()
      ? LocalizationController.to.isArabic
      : true;

  void setLanguage(bool arabic) {
    if (Get.isRegistered<LocalizationController>()) {
      LocalizationController.to.changeLocale(
        arabic
            ? LocalizationController.arabicLocale
            : LocalizationController.englishLocale,
      );
    }
  }

  void toggleCategory(GuideCategory category) {
    if (selectedCategory.value == category) {
      selectedCategory.value = GuideCategory.all;
    } else {
      selectedCategory.value = category;
    }
  }
}
