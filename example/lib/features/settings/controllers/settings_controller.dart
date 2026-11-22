import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/localization_controller.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../core/theme/app_theme_preset.dart';
import '../../../core/theme/theme_controller.dart';

/// Reactive GetX controller managing end-user general settings:
/// - Notifications & alerts preferences (Push, Outbid alerts, Sounds, Announcements).
/// - Complete theme customization (3 Light & 3 Dark presets).
/// - App language switching (Arabic <-> English).
class SettingsController extends GetxController {
  static SettingsController get to => Get.find<SettingsController>();

  static const String _prefKeyPush = 'hosteday_setting_push_enabled';
  static const String _prefKeyAuctionAlerts = 'hosteday_setting_auction_alerts';
  static const String _prefKeySound = 'hosteday_setting_sound_enabled';
  static const String _prefKeyAnnouncements = 'hosteday_setting_announcements';

  final RxBool pushEnabled = true.obs;
  final RxBool auctionAlertsEnabled = true.obs;
  final RxBool soundHapticsEnabled = true.obs;
  final RxBool announcementsEnabled = true.obs;
  final RxBool isRequestingPermission = false.obs;

  PushNotificationService? get _pushService =>
      Get.isRegistered<PushNotificationService>()
      ? PushNotificationService.to
      : null;

  ThemeController get themeController => Get.find<ThemeController>();
  LocalizationController get localizationController =>
      LocalizationController.to;

  bool get isSystemPermissionGranted =>
      _pushService?.isPermissionGranted.value ?? false;

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      pushEnabled.value = prefs.getBool(_prefKeyPush) ?? true;
      auctionAlertsEnabled.value = prefs.getBool(_prefKeyAuctionAlerts) ?? true;
      soundHapticsEnabled.value = prefs.getBool(_prefKeySound) ?? true;
      announcementsEnabled.value = prefs.getBool(_prefKeyAnnouncements) ?? true;
    } catch (_) {}
  }

  Future<void> togglePush(bool value) async {
    pushEnabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyPush, value);
    } catch (_) {}

    if (value && _pushService != null && !isSystemPermissionGranted) {
      await requestSystemPermission();
    }
  }

  Future<void> toggleAuctionAlerts(bool value) async {
    auctionAlertsEnabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyAuctionAlerts, value);
    } catch (_) {}
  }

  Future<void> toggleSound(bool value) async {
    soundHapticsEnabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeySound, value);
    } catch (_) {}
  }

  Future<void> toggleAnnouncements(bool value) async {
    announcementsEnabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyAnnouncements, value);
    } catch (_) {}
  }

  Future<void> requestSystemPermission() async {
    final push = _pushService;
    if (push == null) return;
    isRequestingPermission.value = true;
    try {
      final granted = await push.requestPermission();
      if (granted) {
        Get.snackbar(
          'success'.tr,
          'settings_permission_granted'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.15),
          colorText: Colors.green.shade800,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'warning'.tr,
          'settings_permission_denied'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.amber.withValues(alpha: 0.15),
          colorText: Colors.amber.shade900,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      isRequestingPermission.value = false;
    }
  }

  void changeTheme(AppThemePreset preset) {
    themeController.changeTheme(preset);
  }

  void changeLanguage(Locale locale) {
    localizationController.changeLocale(locale);
  }

  void toggleLanguage() {
    localizationController.toggleLanguage();
  }
}
