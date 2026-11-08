/// API endpoint paths used by the Notifications feature.
class NotificationApiPaths {
  const NotificationApiPaths._();

  static const String registerDevicePath = '/api/notifications/devices/register';
  static const String unregisterDevicePath =
      '/api/notifications/devices/unregister';
  static const String sendNotificationPath = '/api/notifications/send';
}

