// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

class _RuntimeBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    expect(key, 'assets/config/hosteday.json');
    final bytes = Uint8List.fromList(utf8.encode(
        '{"project_domain":"max.hosteday.com","project_api_key":null,"realtime_app_key":null,"realtime_host":null}'));
    return ByteData.sublistView(bytes);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Hosteday.dispose);

  test('new API initializes without optional keys or realtime', () async {
    final client = await Hosteday.initializeApp(options: {
      HostedayOptionKeys.projectDomain: 'max.hosteday.com',
      HostedayOptionKeys.projectApiKey: null,
      HostedayOptionKeys.realtimeAppKey: null,
      HostedayOptionKeys.realtimeHost: null,
    });
    expect(Hosteday.client, same(client));
    expect(client.config.defaultHeaders, isEmpty);
    expect(client.config.hasRealtime, isFalse);
    expect(client.host, 'https://max.hosteday.com');
    expect(client.staticPages['info'], 'https://max.hosteday.com/info');
    expect(client.storageUrl('products/image.png'),
        'https://max.hosteday.com/storage/products/image.png');
  });
  test('legacy facade shares initialization and disposal', () async {
    await HosteDay.initializeApp(
        options: {HosteDayOptionKeys.projectDomain: 'max.hosteday.com'});
    expect(HosteDay.client, same(Hosteday.client));
    const HosteDayException oldError = HosteDayException('legacy');
    expect(oldError, isA<HostedayException>());
    final HosteDayClient oldClient = Hosteday.client;
    expect(oldClient, same(Hosteday.client));
    await HosteDay.dispose();
    expect(Hosteday.isInitialized, isFalse);
  });
  test('uninitialized SDK keeps its descriptive StateError', () {
    expect(
        () => Hosteday.client,
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('initializeApp'))));
  });
  test('loads actual runtime asset shape with optional nulls', () async {
    await Hosteday.initializeFromAsset(bundle: _RuntimeBundle());
    expect(Hosteday.client.apiBaseUrl, 'https://max.hosteday.com/api');
    expect(Hosteday.config.hasRealtime, isFalse);
  });
}
