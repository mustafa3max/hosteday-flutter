import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

    test('switches presence channels: presence-auction.1 -> unsubscribe -> presence-auction.2', () async {
      final authChannels = <String>[];
      final wsFrames = <Map<String, dynamic>>[];
      final frameController = StreamController<Map<String, dynamic>>.broadcast();

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);
          socket.add(jsonEncode(<String, dynamic>{
            'event': 'pusher:connection_established',
            'data': jsonEncode(<String, dynamic>{
              'socket_id': '999.111',
              'activity_timeout': 120,
            }),
          }));
          socket.listen((dynamic message) {
            if (message is String) {
              final decoded = jsonDecode(message) as Map<String, dynamic>;
              wsFrames.add(decoded);
              if (!frameController.isClosed) {
                frameController.add(decoded);
              }
            }
          });
          return;
        }

        if (request.uri.path.endsWith('/broadcasting/auth-manual')) {
          final rawBody = await utf8.decoder.bind(request).join();
          final params = Uri.splitQueryString(rawBody);
          final ch = params['channel_name'] ?? '';
          authChannels.add(ch);
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(<String, dynamic>{
              'auth': 'test-pusher-key:sig-$ch',
              'channel_data': jsonEncode(<String, dynamic>{
                'user_id': 'u1',
                'user_info': <String, dynamic>{'name': 'Tester'},
              }),
            }));
          await request.response.close();
          return;
        }

        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });

      final storage = MemoryHostedayAuthStorage();
      await storage.write(
        HostedayAuthStorageKeys.accessToken,
        'user-bearer-token',
      );
      final config = HostedayConfig.fromOptions({
        'base_url': 'http://127.0.0.1:${server.port}',
        'project_api_key': 'test-proj-token',
        'realtime_app_key': 'test-pusher-key',
        'realtime_host': '127.0.0.1',
        'realtime_port': server.port,
        'realtime_scheme': 'ws',
      });

      final realtime = HostedayRealtimeClient(
        config: config,
        authStorage: storage,
      );

      Future<void> waitForFrame(String event, String channel) async {
        bool matches(Map<String, dynamic> f) {
          if (f['event'] != event) return false;
          final data = f['data'];
          if (data is Map) return data['channel'] == channel;
          return false;
        }

        if (wsFrames.any(matches)) return;
        await frameController.stream
            .firstWhere(matches)
            .timeout(const Duration(seconds: 5));
      }

      try {
        await realtime.connect();
        if (!realtime.isConnected) {
          await realtime.onConnectionStateChanged
              .firstWhere((connected) => connected)
              .timeout(const Duration(seconds: 5));
        }

        // 1. Subscribe to presence-auction.1
        final ch1 = await realtime.subscribePresence('auction.1');
        expect(ch1.name, 'presence-auction.1');
        await waitForFrame('pusher:subscribe', 'presence-auction.1');
        expect(authChannels, contains('presence-auction.1'));

        // 2. Unsubscribe from presence-auction.1
        await realtime.unsubscribe('presence-auction.1');
        await waitForFrame('pusher:unsubscribe', 'presence-auction.1');
        expect(
          realtime.getChannel('auction.1', type: HostedayChannelType.presence),
          isNull,
        );

        // 3. Immediately subscribe to presence-auction.2
        final ch2 = await realtime.subscribePresence('auction.2');
        expect(ch2.name, 'presence-auction.2');
        await waitForFrame('pusher:subscribe', 'presence-auction.2');
        expect(authChannels, contains('presence-auction.2'));
      } finally {
        await realtime.disconnect();
        await frameController.close();
        await server.close(force: true);
      }
    });
  });
}
