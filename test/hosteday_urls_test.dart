import 'package:flutter_test/flutter_test.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

void main() {
  for (final domain in [
    'max.hosteday.com',
    'https://max.hosteday.com/',
    'max.hosteday.com/api/'
  ]) {
    test('normalizes project domain $domain', () {
      final config = HostedayConfig.fromOptions({'project_domain': domain});
      expect(config.host, 'https://max.hosteday.com');
      expect(config.apiBaseUrl, 'https://max.hosteday.com/api');
    });
  }
  test('preserves development HTTP and port', () {
    final config = HostedayConfig.fromOptions(
        {'project_domain': 'http://localhost:8787/'});
    expect(config.host, 'http://localhost:8787');
    expect(config.uri('products').toString(),
        'http://localhost:8787/api/products');
  });
  test('missing domain is a descriptive configuration error', () {
    expect(
        () => HostedayConfig.fromOptions({}),
        throwsA(isA<ArgumentError>()
            .having((e) => e.message, 'message', contains('project_domain'))));
  });
  test('direct configuration with custom base path remains supported', () {
    const config = HostedayConfig(baseUrl: 'https://example.com/v2');
    expect(config.host, 'https://example.com');
    expect(
        config.uri('products').toString(), 'https://example.com/v2/products');
  });
  test('public links and external media', () {
    final urls = HostedayUrlResolver(projectDomain: 'max.hosteday.com');
    final pages = HostedayStaticPages(urls);
    expect(pages['info'], 'https://max.hosteday.com/info');
    expect(pages['/info/'], 'https://max.hosteday.com/info');
    expect(urls.storage('products/image.png'),
        'https://max.hosteday.com/storage/products/image.png');
    expect(urls.storage('/storage/products//image.png/'),
        'https://max.hosteday.com/storage/products/image.png');
    expect(urls.storage('https://cdn.example.com/image.png?size=2'),
        'https://cdn.example.com/image.png?size=2');
    expect(urls.storage('products/my photo.png'),
        'https://max.hosteday.com/storage/products/my%20photo.png');
  });
  for (final path in [
    '',
    '../info',
    '%2e%2e/info',
    'foo/../info',
    'https://evil.example/info',
    '/info?x=1',
    '/info#x',
    'a/b'
  ]) {
    test('rejects invalid page slug $path', () {
      final urls = HostedayUrlResolver(projectDomain: 'max.hosteday.com');
      expect(() => urls.page(path), throwsArgumentError);
    });
  }
}
