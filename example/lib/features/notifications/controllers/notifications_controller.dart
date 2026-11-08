import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../../../core/notifications/push_notification_service.dart';

enum NotificationTargetType { topic, deviceToken }

/// GetX reactive controller for the Notifications feature.
class NotificationsController extends GetxController {
  late final TextEditingController tokenController = TextEditingController();
  late final TextEditingController titleController = TextEditingController(
    text: 'test_push_title'.tr,
  );
  late final TextEditingController bodyController = TextEditingController(
    text: 'test_push_body'.tr,
  );
  late final TextEditingController targetController = TextEditingController(
    text: 'all',
  );

  final Rx<NotificationTargetType> targetType = NotificationTargetType.topic.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingDevices = false.obs;
  final RxBool generalAnnouncements = true.obs;
  final RxString deviceId = ''.obs;
  final RxString message = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxString lastResultJson = ''.obs;
  final RxList<Map<String, dynamic>> registeredDevices =
      <Map<String, dynamic>>[].obs;

  PushNotificationService? get _pushService =>
      Get.isRegistered<PushNotificationService>()
          ? PushNotificationService.to
          : null;

  String get currentPlatformName {
    if (kIsWeb) return 'Web (Browser)';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      default:
        return 'unknown'.tr;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _bindPushService();
    _loadDeviceId();
    fetchRegisteredDevices();
  }

  Future<void> _loadDeviceId() async {
    final push = _pushService;
    if (push != null) {
      deviceId.value = await push.getDeviceId();
    }
  }

  /// Fetches devices registered under the current user account from HosteDay.
  Future<void> fetchRegisteredDevices() async {
    if (!Hosteday.isInitialized) return;
    isLoadingDevices.value = true;
    try {
      final list = await Hosteday.notifications.getRegisteredDevices();
      registeredDevices.assignAll(list);
    } catch (_) {
      // Ignored if user is unauthenticated or guest
    } finally {
      isLoadingDevices.value = false;
    }
  }

  void _bindPushService() {
    final push = _pushService;
    if (push != null) {
      if (push.fcmToken.value.isNotEmpty) {
        tokenController.text = push.fcmToken.value;
      }
      ever(push.fcmToken, (String token) {
        if (token.isNotEmpty) {
          tokenController.text = token;
        }
      });
    }
  }

  @override
  void onClose() {
    tokenController.dispose();
    titleController.dispose();
    bodyController.dispose();
    targetController.dispose();
    super.onClose();
  }

  void clearFeedback() {
    message.value = '';
    errorMessage.value = '';
    lastResultJson.value = '';
  }

  /// Copies the real FCM device token to clipboard for testing from HosteDay dashboard.
  Future<void> copyFcmToken() async {
    final push = _pushService;
    final token = push?.fcmToken.value ?? tokenController.text.trim();
    if (token.isEmpty) {
      errorMessage.value = 'fcm_token_empty_error'.tr;
      return;
    }

    await Clipboard.setData(ClipboardData(text: token));
    message.value = 'fcm_token_copied'.tr;
  }

  /// Toggles push notifications on or off.
  Future<void> togglePush(bool enable) async {
    if (enable) {
      await requestPermissionAndEnable();
    } else {
      await disablePush();
    }
  }

  /// Disables push notifications and unregisters device token.
  Future<void> disablePush() async {
    final push = _pushService;
    final token = push?.fcmToken.value ?? tokenController.text.trim();
    if (token.isNotEmpty) {
      try {
        final devId = await push?.getDeviceId();
        await Hosteday.notifications.unregisterDeviceToken(
          token: token,
          deviceId: devId,
          action: 'unlink',
        );
      } catch (_) {}
    }
    push?.isPermissionGranted.value = false;
    message.value = 'push_disabled_msg'.tr;
  }

  /// Toggles general announcements subscription.
  Future<void> toggleGeneralAnnouncements(bool enable) async {
    generalAnnouncements.value = enable;
    final push = _pushService;
    if (enable) {
      await push?.subscribeToTopic('all');
      message.value = 'subscribed_announcements_msg'.tr;
    } else {
      await push?.unsubscribeFromTopic('all');
      message.value = 'unsubscribed_announcements_msg'.tr;
    }
  }

  /// Send a friendly test alert to this device.
  Future<void> sendTestPush() async {
    final push = _pushService;
    isLoading.value = true;
    clearFeedback();

    try {
      // 1. Ensure permission is requested if not already granted
      if (push != null && !push.isPermissionGranted.value) {
        await push.requestPermission();
      }

      final testTitle = 'test_push_title'.tr;
      final testBody = 'test_push_body'.tr;

      // 2. Display the local visual notification & add to inbox immediately
      await push?.showLocalNotificationDirect(
        title: testTitle,
        body: testBody,
        data: <String, dynamic>{
          'type': 'test_alert',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // 3. Attempt background server dispatch if device token exists
      final target = push?.fcmToken.value ?? tokenController.text.trim();
      if (target.isNotEmpty) {
        try {
          await Hosteday.notifications.sendNotification(
            title: testTitle,
            body: testBody,
            recipientToken: target,
            data: <String, dynamic>{
              'type': 'test_alert',
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        } catch (serverError) {
          debugPrint(
              '[NotificationsController] Server push dispatch notice: $serverError');
        }
      }

      message.value = 'test_push_body'.tr;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Requests permission from user and activates push notifications.
  Future<void> requestPermissionAndEnable() async {
    final push = _pushService;
    if (push == null) return;

    isLoading.value = true;
    clearFeedback();

    try {
      final granted = await push.requestPermission();
      if (granted) {
        message.value = 'subscribed_announcements_msg'.tr;
        await fetchRegisteredDevices();
      } else {
        errorMessage.value = 'push_disabled_msg'.tr;
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Clears the in-memory/recent notifications history inbox.
  void clearHistory() {
    _pushService?.notificationsHistory.clear();
  }

  /// Formats notification timestamp into a friendly human-readable format.
  String formatNotificationTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '';
    }
  }
}
