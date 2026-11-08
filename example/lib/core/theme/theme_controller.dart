import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme_factory.dart';
import 'app_theme_preset.dart';

/// Manages multi-theme state (6 presets: 3 Light, 3 Dark) and persistence via GetX.
class ThemeController extends GetxController {
  static const String _storageKey = 'hosteday_selected_theme_preset';

  final Rx<AppThemePreset> currentPreset =
      AppThemePreset.cyberMidnightDark.obs;

  bool get isDark => currentPreset.value.isDark;

  ThemeData get currentTheme => AppThemeFactory.build(currentPreset.value);

  @override
  void onInit() {
    super.onInit();
    _restoreSavedTheme();
  }

  Future<void> _restoreSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_storageKey);
      if (savedId != null && savedId.isNotEmpty) {
        final preset = AppThemePreset.fromId(savedId);
        currentPreset.value = preset;
        Get.changeTheme(AppThemeFactory.build(preset));
      }
    } catch (_) {
      // Gracefully fall back to default cyberMidnightDark
    }
  }

  Future<void> changeTheme(AppThemePreset preset) async {
    if (currentPreset.value == preset) return;

    currentPreset.value = preset;
    Get.changeTheme(AppThemeFactory.build(preset));

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, preset.id);
    } catch (_) {}
  }
}

