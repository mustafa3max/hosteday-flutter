import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
        HostedayOptionKeys.firebaseStorageBucket:
            'test-app.firebasestorage.app',
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

    test(
        'syncDeviceToken transmits token, device metadata, and Bearer authorization',
        () async {
      http.Request? capturedRequest;
      final sdk = HostedayClient(
        config: HostedayConfig.fromOptions(const {
          HostedayOptionKeys.projectDomain: 'test-app.hosteday.com',
          HostedayOptionKeys.notificationsEnabled: true,
        }),
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({'success': true, 'message': 'Device token synced'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(sdk.dispose);

      final result = await sdk.notifications.syncDeviceToken(
        token: 'fcm_token_12345',
        accessToken: 'user_jwt_access_token',
        deviceType: 'web',
        deviceId: 'device_uuid_99',
        deviceName: 'Web Browser',
      );

      expect(result['success'], isTrue);
      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.url.path, '/api/notifications/devices/register');
      expect(capturedRequest!.headers['authorization'],
          'Bearer user_jwt_access_token');

      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(body['device_token'], 'fcm_token_12345');
      expect(body['device_type'], 'web');
      expect(body['device_name'], 'Web Browser');
      expect(body['device_id'], 'device_uuid_99');
    });

    test(
        'syncDeviceToken handles 404 fallback between /api/device-tokens and /api/notifications/devices/register',
        () async {
      final pathsCalled = <String>[];
      final sdk = HostedayClient(
        config: HostedayConfig.fromOptions(const {
          HostedayOptionKeys.projectDomain: 'test-app.hosteday.com',
          HostedayOptionKeys.notificationsEnabled: true,
        }),
        httpClient: MockClient((request) async {
          pathsCalled.add(request.url.path);
          if (request.url.path == '/api/device-tokens') {
            return http.Response(
              '{"message": "Not Found"}',
              404,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({'success': true, 'message': 'Device token synced'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(sdk.dispose);

      final result = await sdk.notifications.syncDeviceToken(
        token: 'fcm_token_fallback',
        accessToken: 'jwt_token',
        deviceType: 'web',
        endpoint: '/api/device-tokens',
      );

      expect(result['success'], isTrue);
      expect(
          pathsCalled,
          containsAllInOrder(
              ['/api/device-tokens', '/api/notifications/devices/register']));
    });
  });
}
