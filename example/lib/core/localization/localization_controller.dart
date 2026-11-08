import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reactive GetX controller for app-wide localization (Arabic <-> English).
///
/// Features:
/// - Instant reactive language toggling across all screens with `Get.updateLocale`.
/// - Automatic persistence via `SharedPreferences`.
/// - RTL / LTR layout adaptation.
class LocalizationController extends GetxController {
  static LocalizationController get to => Get.find<LocalizationController>();

  static const String _prefKeyLanguage = 'hosteday_app_language_code';

  static const Locale arabicLocale = Locale('ar', 'SA');
  static const Locale englishLocale = Locale('en', 'US');

  final Rx<Locale> currentLocale = arabicLocale.obs;

  bool get isArabic => currentLocale.value.languageCode == 'ar';
  bool get isEnglish => currentLocale.value.languageCode == 'en';

  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  String get currentLanguageName => isArabic ? 'العربية' : 'English';
  String get targetLanguageName => isArabic ? 'English' : 'العربية';

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKeyLanguage);
      if (savedCode != null) {
        if (savedCode == 'en') {
          currentLocale.value = englishLocale;
          await Get.updateLocale(englishLocale);
        } else {
          currentLocale.value = arabicLocale;
          await Get.updateLocale(arabicLocale);
        }
      }
    } catch (_) {}
  }

  /// Sets the application locale and updates persistent storage.
  Future<void> changeLocale(Locale locale) async {
    if (currentLocale.value == locale) return;
    currentLocale.value = locale;
    await Get.updateLocale(locale);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyLanguage, locale.languageCode);
    } catch (_) {}
  }

  /// Toggles between Arabic and English.
  Future<void> toggleLanguage() async {
    final target = isArabic ? englishLocale : arabicLocale;
    await changeLocale(target);
  }
}
