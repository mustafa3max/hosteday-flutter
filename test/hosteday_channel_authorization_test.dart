import 'package:flutter_test/flutter_test.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HostedayChannelAuthorizationDelegate dynamic headers', () {
    test('builds and sends Accept, X-Api-Token, and Authorization dynamically',
        () async {
      String? dynamicToken = 'token-123';
      late Map<String, String> capturedHeaders;
      late Map<String, String> capturedBody;

      final mockClient = MockClient((request) async {
        capturedHeaders = Map<String, String>.from(request.headers);
        capturedBody = Map<String, String>.from(request.bodyFields);
        return http.Response('{"auth": "test-key:signature"}', 200);
      });

      final delegate = HostedayChannelAuthorizationDelegate.forPrivateChannel(
        authorizationEndpoint:
            Uri.parse('https://example.com/api/broadcasting/auth-manual'),
        headersBuilder: () async {
          return {
            'Accept': 'application/json',
            'X-Api-Token': 'proj-api-token-999',
            'Authorization': 'Bearer $dynamicToken',
          };
        },
        httpClient: mockClient,
      );

      final authData1 =
          await delegate.authorizationData('1234.5678', 'private-orders');

      expect(authData1.authKey, 'test-key:signature');
      expect(capturedHeaders['Accept'], 'application/json');
      expect(capturedHeaders['X-Api-Token'], 'proj-api-token-999');
      expect(capturedHeaders['Authorization'], 'Bearer token-123');
      expect(capturedBody['socket_id'], '1234.5678');
      expect(capturedBody['channel_name'], 'private-orders');

      // Now change token dynamically
      dynamicToken = 'refreshed-token-456';
      final authData2 =
          await delegate.authorizationData('1234.5678', 'private-orders');

      expect(authData2.authKey, 'test-key:signature');
      expect(capturedHeaders['Authorization'], 'Bearer refreshed-token-456');
    });

    test('parses presence channel auth data with channel_data', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"auth": "test-key:presence-sig", "channel_data": "{\\"user_id\\": 42}"}',
          200,
        );
      });

      final delegate = HostedayChannelAuthorizationDelegate.forPresenceChannel(
        authorizationEndpoint:
            Uri.parse('https://example.com/api/broadcasting/auth-manual'),
        headersBuilder: () async {
          return {
            'Accept': 'application/json',
            'X-Api-Token': 'api-token',
            'Authorization': 'Bearer user-token',
          };
        },
        httpClient: mockClient,
      );

      final presenceData = await delegate.authorizationData(
        '9999.0000',
        'presence-auction.room',
      );

      expect(presenceData.authKey, 'test-key:presence-sig');
      expect(presenceData.channelDataEncoded, '{"user_id": 42}');
    });

    test('throws HostedayRealtimeAuthorizationException when status is not 200',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"message": "Unauthorized"}', 401);
      });

      final delegate = HostedayChannelAuthorizationDelegate.forPrivateChannel(
        authorizationEndpoint:
            Uri.parse('https://example.com/api/broadcasting/auth-manual'),
        headersBuilder: () async {
          return {
            'Accept': 'application/json',
            'X-Api-Token': 'api-token',
            'Authorization': 'Bearer user-token',
          };
        },
        httpClient: mockClient,
      );

      expect(
        () => delegate.authorizationData('1234.5678', 'private-room'),
        throwsA(isA<HostedayRealtimeAuthorizationException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        )),
      );
    });
  });

  group('HostedayRealtimeClient buildAuthorizationHeaders', () {
    test('retrieves updated token from auth storage dynamically', () async {
      final storage = MemoryHostedayAuthStorage();
      final config = HostedayConfig.fromOptions({
        'project_domain': 'test.hosteday.com',
        'project_api_key': 'test-proj-token',
      });

      final realtime = HostedayRealtimeClient(
        config: config,
        authStorage: storage,
      );

      // Before login: no token
      var headers = await realtime.buildAuthorizationHeaders();
      expect(headers['Accept'], 'application/json');
      expect(headers['X-Api-Token'], 'test-proj-token');
      expect(headers.containsKey('Authorization'), isFalse);

      // User logs in
      await storage.write(
        HostedayAuthStorageKeys.accessToken,
        'new-user-access-token',
      );

      headers = await realtime.buildAuthorizationHeaders();
      expect(headers['Accept'], 'application/json');
      expect(headers['X-Api-Token'], 'test-proj-token');
      expect(headers['Authorization'], 'Bearer new-user-access-token');
    });
  });
}
