import 'dart:async';

import 'package:flutter/foundation.dart';

import '../auth/hosteday_token_provider.dart';
import '../config/hosteday_config.dart';
import '../exceptions/hosteday_exception.dart';
import '../http/hosteday_http_client.dart';
import 'hosteday_notification_response.dart';

/// Manages HosteDay push notifications, device tokens, topics, and notification dispatching.
class HosteDayNotificationClient {
  /// The configuration containing notification paths and settings.
  final HostedayConfig config;

  /// The HTTP client used to send requests to HosteDay.
  final HosteDayHttpClient http;

  /// The provider used to retrieve authenticated user tokens.
  final HosteDayTokenProvider? tokenProvider;

  final ValueNotifier<String?> _currentTokenNotifier =
      ValueNotifier<String?>(null);

  final StreamController<String?> _tokenStreamController =
      StreamController<String?>.broadcast();

  final Set<String> _subscribedTopics = <String>{};

  /// The currently cached device ID, if supplied during registration.
  String? currentDeviceId;

  /// The currently cached device platform type, if supplied during registration.
  String? currentDeviceType;

  /// The currently cached device or browser name, if supplied during registration.
  String? currentDeviceName;

  bool _disposed = false;

  /// Creates a notification client with the supplied [config] and [http] client.
  HosteDayNotificationClient({
    required this.config,
    required this.http,
    this.tokenProvider,
  }) {
    final defaultTopic = config.defaultNotificationTopic;
    if (defaultTopic != null && defaultTopic.isNotEmpty) {
      _subscribedTopics.add(defaultTopic);
    }
  }

  /// Whether push notification features are enabled in [config].
  bool get isEnabled => config.notificationsEnabled;

  /// The currently registered device token, or null if none is registered.
  String? get currentToken => _currentTokenNotifier.value;

  /// Notifier for listening to changes in the registered device token.
  ValueListenable<String?> get tokenNotifier => _currentTokenNotifier;

  /// Stream of device token changes.
  Stream<String?> get onTokenChanged => _tokenStreamController.stream;

  /// Set of topics currently subscribed to.
  Set<String> get subscribedTopics =>
      Set<String>.unmodifiable(_subscribedTopics);

  /// Registers or updates a device token on the HosteDay server.
  ///
  /// When a user is signed in, the token is linked to the authenticated user.
  /// Otherwise, it is stored for anonymous/guest device notifications.
  Future<Map<String, dynamic>> registerDeviceToken({
    required String token,
    String? deviceType,
    String? deviceId,
    String? deviceName,
  }) async {
    _ensureNotDisposed();

    final cleanToken = token.trim();
    if (cleanToken.isEmpty) {
      throw const HosteDayException('A valid device token is required.');
    }

    final hasAuth = await _hasAuthenticatedUser();

    final body = <String, dynamic>{
      'device_token': cleanToken,
      'token': cleanToken,
      if (deviceType != null && deviceType.isNotEmpty)
        'device_type': deviceType,
      if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
      if (deviceName != null && deviceName.isNotEmpty)
        'device_name': deviceName,
    };

    final response = await http.post(
      config.registerDeviceTokenPath,
      body: body,
      withAuth: hasAuth,
    );

    _currentTokenNotifier.value = cleanToken;
    currentDeviceId = deviceId;
    currentDeviceType = deviceType;
    currentDeviceName = deviceName;
    _tokenStreamController.add(cleanToken);

    return response;
  }

  /// Unregisters a device token on the HosteDay server.
  ///
  /// Specify [action] as `'unlink'` to detach user account without dropping guest push,
  /// or set [logoutOnly] to true when signing out.
  Future<Map<String, dynamic>> unregisterDeviceToken({
    required String token,
    String? deviceId,
    String? action = 'unlink',
    bool? logoutOnly,
  }) async {
    _ensureNotDisposed();

    final cleanToken = token.trim();
    if (cleanToken.isEmpty) {
      return <String, dynamic>{};
    }

    final hasAuth = await _hasAuthenticatedUser();

    final body = <String, dynamic>{
      'device_token': cleanToken,
      'token': cleanToken,
      if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
      if (action != null && action.isNotEmpty) 'action': action,
      if (logoutOnly != null) 'logout_only': logoutOnly,
    };

    final response = await http.post(
      config.unregisterDeviceTokenPath,
      body: body,
      withAuth: hasAuth,
    );

    if (_currentTokenNotifier.value == cleanToken) {
      _currentTokenNotifier.value = null;
      _tokenStreamController.add(null);
    }

    return response;
  }

  /// Retrieves the list of devices registered for the currently authenticated user.
  Future<List<Map<String, dynamic>>> getRegisteredDevices() async {
    _ensureNotDisposed();

    final hasAuth = await _hasAuthenticatedUser();

    final response = await http.get(
      config.registeredDevicesPath,
      withAuth: hasAuth,
    );

    final rawList = response['data'] ??
        response['devices'] ??
        response['records'] ??
        response['items'];

    if (rawList is List) {
      return rawList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return <Map<String, dynamic>>[];
  }

  /// Sends or dispatches an immediate push notification through the server gateway.
  ///
  /// Specify [recipientUserId], [recipientToken], or [topic] to target recipients.
  Future<HosteDayNotificationResponse> sendNotification({
    required String title,
    required String body,
    String? recipientUserId,
    String? recipientToken,
    String? topic,
    Map<String, dynamic>? data,
    String? provider,
  }) async {
    _ensureNotDisposed();

    final cleanTitle = title.trim();
    final cleanBody = body.trim();

    if (cleanTitle.isEmpty) {
      throw const HosteDayException('A notification title is required.');
    }

    if (cleanBody.isEmpty) {
      throw const HosteDayException('A notification body is required.');
    }

    final targetTopic = topic ?? config.defaultNotificationTopic;
    final hasAuth = await _hasAuthenticatedUser();

    final payload = <String, dynamic>{
      'title': cleanTitle,
      'body': cleanBody,
      if (recipientUserId != null && recipientUserId.isNotEmpty)
        'recipient_user_id': recipientUserId,
      if (recipientToken != null && recipientToken.isNotEmpty)
        'recipient_token': recipientToken,
      if (targetTopic != null && targetTopic.isNotEmpty)
        'topic': targetTopic,
      if (data != null && data.isNotEmpty) 'data': data,
      if (provider != null && provider.isNotEmpty) 'provider': provider,
    };

    final response = await http.post(
      config.sendNotificationPath,
      body: payload,
      withAuth: hasAuth,
    );

    return HosteDayNotificationResponse.fromJson(response);
  }

  /// Subscribes the client to a notification [topic].
  Future<void> subscribeToTopic(String topic) async {
    _ensureNotDisposed();
    final cleanTopic = topic.trim();
    if (cleanTopic.isEmpty) {
      return;
    }

    _subscribedTopics.add(cleanTopic);
  }

  /// Unsubscribes the client from a notification [topic].
  Future<void> unsubscribeFromTopic(String topic) async {
    _ensureNotDisposed();
    final cleanTopic = topic.trim();
    _subscribedTopics.remove(cleanTopic);
  }

  /// Releases resources used by the notification client.
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _currentTokenNotifier.dispose();
    _tokenStreamController.close();
  }

  Future<bool> _hasAuthenticatedUser() async {
    final token = await tokenProvider?.getToken();
    return token != null && token.trim().isNotEmpty;
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const HosteDayException('Notification client has been disposed.');
    }
  }
}

/// Preferred spelling of [HosteDayNotificationClient].
typedef HostedayNotificationClient = HosteDayNotificationClient;

