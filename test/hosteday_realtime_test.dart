import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _RealtimeAssetBundle extends CachingAssetBundle {
  _RealtimeAssetBundle(this.payload);

  final Map<String, Object?> payload;

  @override
  Future<ByteData> load(String key) async {
    expect(key, 'assets/hosteday_config.json');
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
    return ByteData.sublistView(bytes);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Hosteday.dispose);

  test(
      'builds Pusher v7 WebSocket URI with ws1.hosteday.com:443 and normalizes wss port 8080',
      () async {
    final bundle = _RealtimeAssetBundle({
      'project_domain': 'flutter.hosteday.com',
      'api_base_url': 'https://flutter.hosteday.com',
      'realtime_app_key': 'vgwmaomvcvorgqgnfjeq',
      'realtime_host': 'ws1.hosteday.com',
      'realtime_port': 8080,
      'realtime_scheme': 'wss',
    });

    await Hosteday.initializeApp(
      bundle: bundle,
      connectRealtime: false,
    );

    final uri = Hosteday.realtime.resolvedWebsocketUri;
    expect(
      uri.toString(),
      'wss://ws1.hosteday.com:443/app/vgwmaomvcvorgqgnfjeq?protocol=7&client=dart&version=2.4.0&flash=false',
    );
  });

  test(
      'parses Laravel Reverb pusher:connection_established JSON string, flips isConnected to true, and authorizes presence channel',
      () async {
    final bundle = _RealtimeAssetBundle({
      'project_domain': 'flutter.hosteday.com',
      'api_base_url': 'https://flutter.hosteday.com',
      'project_api_key': 'proj-api-key',
      'realtime_app_key': 'vgwmaomvcvorgqgnfjeq',
      'realtime_host': 'ws1.hosteday.com',
      'realtime_port': 443,
      'realtime_scheme': 'wss',
    });

    final storage = MemoryHostedayAuthStorage();
    await storage.write(HostedayAuthStorageKeys.accessToken, 'user-jwt-123');

    await Hosteday.initializeApp(
      bundle: bundle,
      authStorage: storage,
      connectRealtime: false,
    );

    expect(Hosteday.realtime.isConnected, isFalse);

    final states = <bool>[];
    final sub = Hosteday.realtime.onConnectionStateChanged.listen(states.add);

    // Simulate Laravel Reverb pusher:connection_established with stringified JSON data
    const reverbFrame = <String, dynamic>{
      'event': 'pusher:connection_established',
      'data': '{"socket_id":"12345.67890","activity_timeout":120}',
    };
    Hosteday.realtime.handleConnectionEstablished(reverbFrame);

    await Future<void>.delayed(Duration.zero);

    expect(Hosteday.realtime.isConnected, isTrue);
    expect(Hosteday.realtime.socketId, '12345.67890');
    expect(states, equals(<bool>[true]));

    // Verify presence channel authorization against /api/broadcasting/auth-manual
    final mockHttp = MockClient((request) async {
      expect(request.url.path, '/api/broadcasting/auth-manual');
      expect(request.headers['Authorization'], 'Bearer user-jwt-123');
      expect(request.bodyFields['socket_id'], '12345.67890');
      expect(request.bodyFields['channel_name'], 'presence-auction.room');
      return http.Response(
        jsonEncode({
          'auth': 'vgwmaomvcvorgqgnfjeq:signed-presence-token',
          'channel_data': jsonEncode({
            'user_id': 'u1',
            'user_info': {'name': 'Ali'},
          }),
        }),
        200,
      );
    });

    final delegate = HostedayChannelAuthorizationDelegate.forPresenceChannel(
      authorizationEndpoint:
          Hosteday.config.uri(Hosteday.config.broadcastingAuthPath),
      headersBuilder: Hosteday.realtime.buildAuthorizationHeaders,
      httpClient: mockHttp,
    );

    final authData = await delegate.authorizationData(
      Hosteday.realtime.socketId!,
      'presence-auction.room',
    );

    expect(authData.authKey, 'vgwmaomvcvorgqgnfjeq:signed-presence-token');
    expect(authData.channelDataEncoded, contains('Ali'));

    await sub.cancel();
  });
}
