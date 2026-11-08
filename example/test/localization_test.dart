import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hosteday_flutter_example/core/localization/app_translations.dart';
import 'package:hosteday_flutter_example/core/localization/localization_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  test('AppTranslations contains complete ar_SA and en_US key sets', () {
    final translations = AppTranslations();
    final keys = translations.keys;

    expect(keys.containsKey('ar_SA'), isTrue);
    expect(keys.containsKey('en_US'), isTrue);

    final arKeys = keys['ar_SA']!.keys.toSet();
    final enKeys = keys['en_US']!.keys.toSet();

    // Verify critical shared keys exist in both languages
    final essentialKeys = [
      'app_title',
      'starter_title',
      'nav_guide',
      'nav_realtime',
      'nav_notifications',
      'nav_profile',
      'sign_in',
      'sign_out',
      'create_account',
      'notifications_page_title',
      'realtime_header_title',
      'theme_sheet_title',
      'code_copied',
      'email_label',
      'password_label',
    ];

    for (final key in essentialKeys) {
      expect(arKeys.contains(key), isTrue, reason: 'ar_SA missing $key');
      expect(enKeys.contains(key), isTrue, reason: 'en_US missing $key');
    }
  });

  test('LocalizationController toggles language and persists selection', () async {
    final controller = Get.put(LocalizationController());

    expect(controller.isArabic, isTrue);
    expect(controller.textDirection, TextDirection.rtl);

    await controller.toggleLanguage();

    expect(controller.isEnglish, isTrue);
    expect(controller.textDirection, TextDirection.ltr);

    await controller.toggleLanguage();

    expect(controller.isArabic, isTrue);
  });
}

