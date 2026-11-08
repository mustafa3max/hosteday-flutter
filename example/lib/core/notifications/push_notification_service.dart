import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../hosteday_config.dart';

/// Top-level background message handler required by Firebase Messaging.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
  debugPrint(
      '[PushNotificationService] Background message received: ${message.messageId}');

  // If the message is a data-only payload, display it in the Android/iOS status bar
  if (message.notification == null && message.data.isNotEmpty) {
    try {
      final localNotifications = FlutterLocalNotificationsPlugin();
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await localNotifications.initialize(initSettings);

      const androidDetails = AndroidNotificationDetails(
        'hosteday_high_importance_channel',
        'Hosteday High Importance Notifications',
        channelDescription:
            'This channel is used for important Hosteday push alerts and automation.',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const details = NotificationDetails(android: androidDetails);

      final title =
          message.data['title']?.toString() ?? 'إشعار جديد من HosteDay';
      final body = message.data['body']?.toString() ??
          message.data['message']?.toString() ??
          '';

      final notifId = (message.messageId?.hashCode ??
              DateTime.now().millisecondsSinceEpoch) &
          0x7FFFFFFF;

      await localNotifications.show(
        notifId,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint(
          '[PushNotificationService] Background local notification error: $e');
    }
  }
}

/// Official multi-platform push notification manager for Hosteday Flutter apps.
///
/// Seamlessly bridges Firebase Cloud Messaging (FCM v1) with the
/// HosteDay Notification Gateway across Android, iOS, Web, and Desktop.
class PushNotificationService extends GetxService {
  static PushNotificationService get to => Get.find<PushNotificationService>();

  static const String _prefKeyApiKey = 'hosteday_firebase_web_api_key';
  static const String _prefKeyVapidKey = 'hosteday_firebase_web_vapid_key';
  static const String _prefKeyAppId = 'hosteday_firebase_web_app_id';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final RxString fcmToken = ''.obs;
  final RxBool isInitialized = false.obs;
  final RxBool isPermissionGranted = false.obs;
  final RxString tokenError = ''.obs;
  final RxString lastReceivedMessage = ''.obs;
  final RxList<Map<String, dynamic>> notificationsHistory =
      <Map<String, dynamic>>[].obs;

  Map<String, dynamic>? _fileWebConfig;

  // Resolved credentials from HosteDayConfig, falling back to Hosteday.config or web file
  String get _apiKey =>
      _fileWebConfig?['apiKey']?.toString() ??
      (Hosteday.isInitialized ? (Hosteday.config.firebaseApiKey ?? '') : '');

  String get _appId =>
      _fileWebConfig?['appId']?.toString() ??
      (Hosteday.isInitialized ? (Hosteday.config.firebaseAppId ?? '') : '');

  String get _messagingSenderId =>
      _fileWebConfig?['messagingSenderId']?.toString() ??
      (Hosteday.isInitialized
          ? (Hosteday.config.firebaseMessagingSenderId ?? '')
          : '');

  String get _projectId =>
      _fileWebConfig?['projectId']?.toString() ??
      (Hosteday.isInitialized &&
              (Hosteday.config.firebaseProjectId?.isNotEmpty ?? false)
          ? Hosteday.config.firebaseProjectId!
          : (HosteDayConfig.firebaseProjectId ?? ''));

  String get _vapidKey =>
      _fileWebConfig?['vapidKey']?.toString() ??
      (Hosteday.isInitialized ? (Hosteday.config.firebaseVapidKey ?? '') : '');

  String get _authDomain =>
      _fileWebConfig?['authDomain']?.toString() ??
      (Hosteday.isInitialized
          ? (Hosteday.config.firebaseAuthDomain ?? '')
          : '');

  String get _storageBucket =>
      _fileWebConfig?['storageBucket']?.toString() ??
      (Hosteday.isInitialized
          ? (Hosteday.config.firebaseStorageBucket ?? '')
          : '');

  String? get _measurementId =>
      _fileWebConfig?['measurementId']?.toString() ??
      (Hosteday.isInitialized ? Hosteday.config.firebaseMeasurementId : null);

  final RxString webApiKey = ''.obs;
  final RxString webVapidKey = ''.obs;
  final RxString webAppId = ''.obs;

  static const String channelId = 'hosteday_high_importance_channel';
  static const String channelName = 'Hosteday High Importance Notifications';
  static const String channelDescription =
      'This channel is used for important Hosteday push alerts and automation.';

  /// Initializes native push notifications, loads saved keys, and links with HosteDay.
  Future<void> initialize() async {
    if (isInitialized.value) return;
    if (Hosteday.isInitialized && !Hosteday.config.notificationsEnabled) return;

    try {
      // 1. Load Web Firebase config file (web/firebase-config.json)
      await _loadWebConfigFile();

      // 2. Restore saved Web Credentials if present
      await _restoreSavedWebConfig();

      // 3. Initialize Firebase Core
      await _ensureFirebaseInitialized();

      // 4. Setup Local Notifications (for foreground banners)
      await _setupLocalNotifications();

      // 5. Register Background Handler
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      }

      // 6. Setup Foreground and Click Listeners
      _setupMessageListeners();

      // 7. Request User Notification Permission
      await requestPermission();

      isInitialized.value = true;
      debugPrint('[PushNotificationService] Initialized successfully on ${defaultTargetPlatform.name}');
    } catch (error) {
      tokenError.value = error.toString();
      debugPrint('[PushNotificationService] Initialization error: $error');
    }
  }

  /// Automatically loads Web Firebase configuration from `web/firebase-config.json`.
  Future<void> _loadWebConfigFile() async {
    try {
      final jsonString = await rootBundle.loadString('web/firebase-config.json');
      final data = jsonDecode(jsonString);
      if (data is Map<String, dynamic>) {
        _fileWebConfig = data;
        debugPrint('[PushNotificationService] Loaded web/firebase-config.json successfully');
      }
    } catch (e) {
      debugPrint('[PushNotificationService] Note: web/firebase-config.json not loaded from bundle ($e)');
    }
  }

  /// Restores user-provided Web Push keys from local persistent storage or default config.
  Future<void> _restoreSavedWebConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedApiKey = prefs.getString(_prefKeyApiKey);
      final savedVapid = prefs.getString(_prefKeyVapidKey);
      final savedAppId = prefs.getString(_prefKeyAppId);

      webApiKey.value = (savedApiKey != null && savedApiKey.isNotEmpty)
          ? savedApiKey
          : _apiKey;
      webVapidKey.value = (savedVapid != null && savedVapid.isNotEmpty)
          ? savedVapid
          : _vapidKey;
      webAppId.value = (savedAppId != null && savedAppId.isNotEmpty)
          ? savedAppId
          : _appId;
    } catch (_) {
      webApiKey.value = _apiKey;
      webVapidKey.value = _vapidKey;
      webAppId.value = _appId;
    }
  }

  /// Saves Web Push credentials and re-fetches the real FCM token.
  Future<bool> saveWebConfig({
    required String apiKey,
    required String vapidKey,
    String? appId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyApiKey, apiKey.trim());
      await prefs.setString(_prefKeyVapidKey, vapidKey.trim());
      if (appId != null && appId.trim().isNotEmpty) {
        await prefs.setString(_prefKeyAppId, appId.trim());
        webAppId.value = appId.trim();
      }

      webApiKey.value = apiKey.trim();
      webVapidKey.value = vapidKey.trim();

      tokenError.value = '';

      // If Firebase was already initialized with a dummy key on Web, delete and reinitialize
      if (kIsWeb && Firebase.apps.isNotEmpty) {
        final currentApp = Firebase.app();
        if (currentApp.options.apiKey != apiKey.trim()) {
          await currentApp.delete();
          await Firebase.initializeApp(
            options: FirebaseOptions(
              apiKey: apiKey.trim(),
              appId: (appId != null && appId.trim().isNotEmpty)
                  ? appId.trim()
                  : webAppId.value,
              messagingSenderId: _messagingSenderId,
              projectId: _projectId,
              authDomain: _authDomain,
              storageBucket: _storageBucket,
              measurementId: _measurementId,
            ),
          );
        }
      }
      final token = await _retrieveAndRegisterToken();
      return token != null && token.isNotEmpty;
    } catch (error) {
      tokenError.value = error.toString();
      return false;
    }
  }

  /// Generates a valid test/simulated token for Web testing without waiting for Firebase Console keys.
  Future<String> useSimulatedWebToken() async {
    final simulated =
        'web_token_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
    fcmToken.value = simulated;
    tokenError.value = '';

    final devId = await getDeviceId();
    final devName = getDeviceName();

    await Hosteday.notifications.registerDeviceToken(
      token: simulated,
      deviceType: 'web',
      deviceId: devId,
      deviceName: devName,
    );

    return simulated;
  }

  /// Ensures Firebase App is initialized on the target platform.
  Future<void> _ensureFirebaseInitialized() async {
    if (kIsWeb) {
      // If Firebase was already initialized with mismatched credentials, reinitialize with Hosteday config
      if (Firebase.apps.isNotEmpty) {
        final currentApp = Firebase.app();
        if (currentApp.options.appId != _appId ||
            currentApp.options.messagingSenderId != _messagingSenderId ||
            currentApp.options.apiKey != _apiKey) {
          await currentApp.delete();
        } else {
          return;
        }
      }

      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: _apiKey,
          appId: _appId,
          messagingSenderId: _messagingSenderId,
          projectId: _projectId,
          authDomain: _authDomain,
          storageBucket: _storageBucket,
          measurementId: _measurementId,
        ),
      );
    } else {
      if (Firebase.apps.isNotEmpty) return;
      await Firebase.initializeApp();
    }
  }

  /// Sets up Flutter Local Notifications for displaying foreground popups.
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open Notification',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[PushNotificationService] User tapped notification: ${response.payload}');
      },
    );

    final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.high,
          playSound: true,
        ),
      );
      try {
        await androidImplementation.requestNotificationsPermission();
      } catch (_) {}
    }
  }

  /// Requests notification permissions and registers the resulting device token with HosteDay.
  Future<bool> requestPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      isPermissionGranted.value = granted;

      if (granted) {
        await _retrieveAndRegisterToken();
      }

      return granted;
    } catch (error) {
      tokenError.value = error.toString();
      debugPrint('[PushNotificationService] requestPermission failed: $error');
      return false;
    }
  }

  /// Retrieves the actual platform FCM token and registers it with HosteDay.
  Future<String?> _retrieveAndRegisterToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      String? token;

      if (kIsWeb) {
        token = await messaging.getToken(vapidKey: _vapidKey);
      } else {
        token = await messaging.getToken();
      }

      if (token != null && token.isNotEmpty) {
        fcmToken.value = token;
        tokenError.value = '';
        debugPrint('[PushNotificationService] FCM Token obtained: $token');

        final deviceId = await getDeviceId();
        final deviceName = getDeviceName();

        // Automatically register with HosteDay Notification Backend
        try {
          await Hosteday.notifications.registerDeviceToken(
            token: token,
            deviceType: _resolvePlatformName(),
            deviceId: deviceId,
            deviceName: deviceName,
          );
        } catch (e) {
          debugPrint(
              '[PushNotificationService] Server registerDeviceToken notice: $e');
        }

        // Auto-subscribe to default topic 'all' on Native platforms (Android & iOS)
        if (!kIsWeb) {
          try {
            await messaging.subscribeToTopic('all');
            debugPrint(
                '[PushNotificationService] Auto-subscribed to topic: all');
          } catch (e) {
            debugPrint(
                '[PushNotificationService] Topic all auto-subscribe notice: $e');
          }
        }
      } else if (kIsWeb && webVapidKey.value.isEmpty) {
        tokenError.value =
            'يتطلب Web Push في Firebase مفتاح VAPID صالحاً و API Key من مشروع Firebase الخاص بالتطبيق.';
      }

      // Listen for token refreshes
      messaging.onTokenRefresh.listen((refreshedToken) async {
        fcmToken.value = refreshedToken;
        debugPrint('[PushNotificationService] Token refreshed: $refreshedToken');
        try {
          final deviceId = await getDeviceId();
          final deviceName = getDeviceName();
          await Hosteday.notifications.registerDeviceToken(
            token: refreshedToken,
            deviceType: _resolvePlatformName(),
            deviceId: deviceId,
            deviceName: deviceName,
          );
        } catch (e) {
          debugPrint('[PushNotificationService] Server token refresh notice: $e');
        }
      });

      return token;
    } catch (error) {
      tokenError.value = error.toString();
      debugPrint('[PushNotificationService] getToken failed: $error');
      return null;
    }
  }

  /// Sets up foreground and user tap listeners.
  void _setupMessageListeners() {
    // 1. Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[PushNotificationService] Foreground message: ${message.messageId}');
      _recordNotification(message);
      _showLocalNotification(message);
    });

    // 2. User tapped on notification when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[PushNotificationService] Notification opened app: ${message.messageId}');
      _recordNotification(message);
    });

    // 3. App opened from terminated state via notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('[PushNotificationService] App launched from notification: ${message.messageId}');
        _recordNotification(message);
      }
    });
  }

  /// Displays foreground notification as a system popup or Get snackbar.
  /// Displays a local notification immediately and saves it to history.
  Future<void> showLocalNotificationDirect({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final item = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'data': data ?? <String, dynamic>{'type': 'test_alert'},
      'received_at': DateTime.now().toIso8601String(),
    };
    notificationsHistory.insert(0, item);
    lastReceivedMessage.value = '$title: $body';

    if (!kIsWeb) {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      try {
        await _localNotifications.show(
          item['id'].hashCode & 0x7FFFFFFF,
          title,
          body,
          details,
          payload: jsonEncode(data ?? {}),
        );
      } catch (e) {
        debugPrint('[PushNotificationService] Local notification error: $e');
      }
    }

    try {
      if (Get.context != null) {
        Get.snackbar(
          title,
          body,
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF1E1E28),
          colorText: Colors.white,
          icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFF38BDF8)),
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(12),
        );
      }
    } catch (_) {}
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'] ?? 'Hosteday Notification';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    if (!kIsWeb) {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final notifId =
          (message.messageId?.hashCode ?? message.hashCode) & 0x7FFFFFFF;
      try {
        await _localNotifications.show(
          notifId,
          title,
          body,
          details,
          payload: message.data.toString(),
        );
      } catch (e) {
        debugPrint(
            '[PushNotificationService] Local foreground notification error: $e');
      }
    }

    try {
      if (Get.context != null) {
        Get.snackbar(
          title,
          body,
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF1E1E28),
          colorText: Colors.white,
          icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFF38BDF8)),
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(12),
        );
      }
    } catch (_) {}
  }

  void _recordNotification(RemoteMessage message) {
    final item = <String, dynamic>{
      'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': message.notification?.title ?? message.data['title'] ?? 'Notification',
      'body': message.notification?.body ?? message.data['body'] ?? '',
      'data': message.data,
      'received_at': DateTime.now().toIso8601String(),
    };
    notificationsHistory.insert(0, item);
    lastReceivedMessage.value = '${item['title']}: ${item['body']}';
  }

  /// Subscribes to a unified notification topic.
  Future<void> subscribeToTopic(String topic) async {
    final cleanTopic = topic.trim();
    if (cleanTopic.isEmpty) return;

    if (!kIsWeb) {
      try {
        await FirebaseMessaging.instance.subscribeToTopic(cleanTopic);
      } catch (_) {}
    }
    await Hosteday.notifications.subscribeToTopic(cleanTopic);
  }

  /// Unsubscribes from a notification topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    final cleanTopic = topic.trim();
    if (cleanTopic.isEmpty) return;

    if (!kIsWeb) {
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic(cleanTopic);
      } catch (_) {}
    }
    await Hosteday.notifications.unsubscribeFromTopic(cleanTopic);
  }

  String _resolvePlatformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  /// Persistent hardware-like identifier for this client installation.
  Future<String> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString('hosteday_device_uuid');
      if (id == null || id.isEmpty) {
        final rand = Random().nextInt(99999999).toString().padLeft(8, '0');
        id = '${_resolvePlatformName()}_${DateTime.now().millisecondsSinceEpoch}_$rand';
        await prefs.setString('hosteday_device_uuid', id);
      }
      return id;
    } catch (_) {
      return 'device_${_resolvePlatformName()}';
    }
  }

  /// Friendly human-readable device or browser model name.
  String getDeviceName() {
    if (kIsWeb) return 'Web Browser (${defaultTargetPlatform.name})';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android Mobile Device';
      case TargetPlatform.iOS:
        return 'Apple iOS Device';
      case TargetPlatform.macOS:
        return 'macOS Computer';
      case TargetPlatform.windows:
        return 'Windows PC';
      case TargetPlatform.linux:
        return 'Linux Workstation';
      default:
        return 'HosteDay Client';
    }
  }
}
