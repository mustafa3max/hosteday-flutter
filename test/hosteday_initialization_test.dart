import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

class _JsonAssetBundle extends CachingAssetBundle {
  _JsonAssetBundle(this.payload);

  final String payload;
  String? lastRequestedKey;

  @override
  Future<ByteData> load(String key) async {
    lastRequestedKey = key;
    expect(key, 'assets/hosteday_config.json');
    final bytes = Uint8List.fromList(utf8.encode(payload));
    return ByteData.sublistView(bytes);
  }
}

class _MissingAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw FlutterError('Unable to load asset: "$key".');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Hosteday.dispose);

  test('initializes exclusively from assets/hosteday_config.json', () async {
    final bundle = _JsonAssetBundle(jsonEncode({
      'app_name': 'flutter',
      'slug': 'flutter',
      'environment_id': 'env-123',
      'project_domain': 'flutter.hosteday.com',
      'api_base_url': 'https://flutter.hosteday.com',
      'project_api_key': 'secret-api-key',
      'realtime_app_key': 'app-key',
      'realtime_host': 'ws1.hosteday.com',
      'realtime_port': 8080,
      'realtime_scheme': 'wss',
      'realtime_channel': 'environment.env-123',
      'notifications_enabled': true,
      'jobs_enabled': true,
      'firebase_project_id': 'flutter-hosteday-xdqb',
      'features': {
        'push_notifications': true,
        'realtime_websockets': true,
        'database_management': false,
      },
    }));

    final client = await Hosteday.initializeApp(bundle: bundle);

    expect(bundle.lastRequestedKey, 'assets/hosteday_config.json');
    expect(Hosteday.client, same(client));
    expect(client.config.appName, 'flutter');
    expect(client.config.slug, 'flutter');
    expect(client.config.environmentId, 'env-123');
    expect(client.config.baseUrl, 'https://flutter.hosteday.com');
    expect(client.config.apiToken, 'secret-api-key');
    expect(client.config.hasRealtime, isTrue);
    expect(client.config.realtimePort, 8080);
    expect(client.config.realtimeChannel, 'environment.env-123');
    expect(client.config.firebaseProjectId, 'flutter-hosteday-xdqb');
    expect(client.config.jobsEnabled, isTrue);
    expect(client.config.jobsPath, '/api/jobs');
    expect(Hosteday.features.isNotificationsEnabled, isTrue);
    expect(Hosteday.features.isRealtimeEnabled, isTrue);
    expect(Hosteday.features.isDatabaseEnabled, isFalse);
  });

  test('loads minimal assets/hosteday_config.json with optional nulls',
      () async {
    final bundle = _JsonAssetBundle(
      '{"project_domain":"max.hosteday.com","project_api_key":null,"realtime_app_key":null,"realtime_host":null}',
    );

    final client = await Hosteday.initializeApp(bundle: bundle);

    expect(Hosteday.client, same(client));
    expect(client.config.defaultHeaders, isEmpty);
    expect(client.config.hasRealtime, isFalse);
    expect(client.host, 'https://max.hosteday.com');
    expect(client.apiBaseUrl, 'https://max.hosteday.com/api');
    expect(client.staticPages['info'], 'https://max.hosteday.com/info');
    expect(
      client.storageUrl('products/image.png'),
      'https://max.hosteday.com/storage/products/image.png',
    );
  });

  test('throws clear HostedayException when assets/hosteday_config.json is missing',
      () async {
    await expectLater(
      () => Hosteday.initializeApp(bundle: _MissingAssetBundle()),
      throwsA(
        isA<HostedayException>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('assets/hosteday_config.json'),
            contains('pubspec.yaml'),
          ),
        ),
      ),
    );
  });

  test('throws clear HostedayException when JSON is malformed', () async {
    await expectLater(
      () => Hosteday.initializeApp(bundle: _JsonAssetBundle('{invalid-json')),
      throwsA(
        isA<HostedayException>().having(
          (e) => e.message,
          'message',
          contains('assets/hosteday_config.json'),
        ),
      ),
    );
  });

  test('throws clear HostedayException when required fields are missing',
      () async {
    await expectLater(
      () => Hosteday.initializeApp(bundle: _JsonAssetBundle('{"app_name":"x"}')),
      throwsA(
        isA<HostedayException>().having(
          (e) => e.message,
          'message',
          contains('assets/hosteday_config.json'),
        ),
      ),
    );
  });

  test('uninitialized SDK keeps its descriptive StateError', () {
    expect(
      () => Hosteday.client,
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('initializeApp'),
        ),
      ),
    );
  });
}
