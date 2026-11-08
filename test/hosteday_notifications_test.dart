import 'package:flutter_test/flutter_test.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

void main() {
  group('Hosteday Notification Config & Response', () {
    test('parses notification options from configuration map', () {
      final config = HostedayConfig.fromOptions(const <String, Object?>{
        HostedayOptionKeys.projectDomain: 'test-app.hosteday.com',
        HostedayOptionKeys.notificationsEnabled: true,
        HostedayOptionKeys.defaultNotificationTopic: 'general_announcements',
      });

      expect(config.notificationsEnabled, isTrue);
      expect(config.defaultNotificationTopic, 'general_announcements');
      expect(
        config.registerDeviceTokenPath,
        '/api/notifications/devices/register',
      );
      expect(
        config.unregisterDeviceTokenPath,
        '/api/notifications/devices/unregister',
      );
      expect(config.sendNotificationPath, '/api/notifications/send');
      expect(config.registeredDevicesPath, '/api/notifications/devices');
    });

    test('parses Firebase push credentials and background jobs options', () {
      final config = HostedayConfig.fromOptions(const <String, Object?>{
        HostedayOptionKeys.projectDomain: 'test-app.hosteday.com',
        HostedayOptionKeys.firebaseApiKey: 'AIzaSyTestApiKey',
        HostedayOptionKeys.firebaseAppId: '1:123456:web:abcdef',
        HostedayOptionKeys.firebaseMessagingSenderId: '123456',
        HostedayOptionKeys.firebaseProjectId: 'test-app',
        HostedayOptionKeys.firebaseVapidKey: 'BBL8TestVapidKey',
        HostedayOptionKeys.firebaseAuthDomain: 'test-app.firebaseapp.com',
        HostedayOptionKeys.firebaseStorageBucket: 'test-app.firebasestorage.app',
        HostedayOptionKeys.firebaseMeasurementId: 'G-TEST1234',
        HostedayOptionKeys.jobsEnabled: true,
        HostedayOptionKeys.jobsPath: '/api/v1/jobs',
      });

      expect(config.firebaseApiKey, 'AIzaSyTestApiKey');
      expect(config.firebaseAppId, '1:123456:web:abcdef');
      expect(config.firebaseMessagingSenderId, '123456');
      expect(config.firebaseProjectId, 'test-app');
      expect(config.firebaseVapidKey, 'BBL8TestVapidKey');
      expect(config.firebaseAuthDomain, 'test-app.firebaseapp.com');
      expect(config.firebaseStorageBucket, 'test-app.firebasestorage.app');
      expect(config.firebaseMeasurementId, 'G-TEST1234');
      expect(config.jobsEnabled, isTrue);
      expect(config.jobsPath, '/api/v1/jobs');
    });

    test('HostedayNotificationResponse parsing succeeds', () {
      final json = <String, dynamic>{
        'success': true,
        'message_id': 'msg_123456',
        'data': <String, dynamic>{
          'title': 'Test Title',
          'body': 'Test Body',
        },
      };

      final response = HostedayNotificationResponse.fromJson(json);

      expect(response.success, isTrue);
      expect(response.messageId, 'msg_123456');
      expect(response.data?['title'], 'Test Title');
      expect(response.error, isNull);
    });

    test('HostedayNotificationResponse handles error format', () {
      final json = <String, dynamic>{
        'success': false,
        'message': 'Failed to deliver notification.',
      };

      final response = HostedayNotificationResponse.fromJson(json);

      expect(response.success, isFalse);
      expect(response.error, 'Failed to deliver notification.');
      expect(response.messageId, isNull);
    });
  });
}

