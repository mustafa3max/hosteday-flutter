import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  HostedayClient client(Future<http.Response> Function(http.Request) handler,
      {String? key, String? token, String? base}) {
    final value = HostedayClient(
      config: HostedayConfig.fromOptions({
        HostedayOptionKeys.projectDomain: 'max.hosteday.com',
        HostedayOptionKeys.projectApiKey: key,
        HostedayOptionKeys.apiBaseUrl: base,
      }),
      tokenProvider: StaticHostedayTokenProvider(token),
      httpClient: MockClient(handler),
    );
    addTearDown(value.dispose);
    return value;
  }

  for (final path in [
    'products',
    '/products',
    '/api/products',
    '/products//',
    'https://max.hosteday.com/api/products'
  ]) {
    test('GET resolves $path once', () async {
      final sdk = client((request) async {
        expect(request.url.toString(), 'https://max.hosteday.com/api/products');
        expect(request.headers.containsKey('authorization'), isFalse);
        expect(request.headers.containsKey('X-Api-Token'), isFalse);
        return http.Response('{"data":[]}', 200);
      });
      expect(sdk.host, 'https://max.hosteday.com');
      expect(sdk.apiBaseUrl, 'https://max.hosteday.com/api');
      expect(await sdk.get(path), {'data': []});
    });
  }

  for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
    test('$method convenience method adds api and accepts full resource path',
        () async {
      final sdk = client((request) async {
        expect(request.method, method);
        expect(request.url.path, '/api/products/15');
        expect(request.headers['authorization'], 'Bearer user-token');
        expect(request.headers['X-Api-Token'], 'project-key');
        return http.Response('', 204);
      }, key: ' project-key ', token: 'user-token');
      final result = switch (method) {
        'POST' => await sdk.post('/products/15'),
        'PUT' => await sdk.put('/products/15'),
        'PATCH' => await sdk.patch('/products/15'),
        _ => await sdk.delete('/products/15'),
      };
      expect(result, isEmpty);
    });
  }

  test('query, search, filters, id and existing parameters are preserved',
      () async {
    final sdk = client((request) async {
      expect(request.url.path, '/api/products');
      expect(request.url.queryParameters['page'], '2');
      expect(request.url.queryParameters['search'], 'phone');
      expect(request.url.queryParameters['category_id'], '5');
      expect(request.url.queryParameters['sort'], 'name');
      expect(request.url.queryParametersAll['filters[status][]'],
          ['active', 'pending']);
      return http.Response('{}', 200);
    });
    await sdk.get('/products?sort=name', search: 'phone', queryParameters: {
      'page': 2,
      'category_id': 5,
      'ignored': null
    }, filters: {
      'status': ['active', 'pending']
    });
  });

  test('id is encoded as one path segment', () async {
    final sdk = client((request) async {
      expect(request.url.pathSegments.last, 'a/b');
      return http.Response('{}', 200);
    });
    await sdk.get('/products', id: 'a/b');
  });

  for (final key in [null, '', '   ']) {
    test('empty project key is omitted: $key', () async {
      final sdk = client((request) async {
        expect(request.headers.keys.map((key) => key.toLowerCase()),
            isNot(contains('x-api-token')));
        return http.Response('{}', 200);
      }, key: key);
      await sdk.get('/products');
    });
  }

  test('authenticated requests require a token', () async {
    final sdk = client((_) async => throw StateError('Must not send'));
    await expectLater(
        sdk.get('/orders', withAuth: true),
        throwsA(isA<HostedayException>()
            .having((e) => e.statusCode, 'status', 401)));
  });

  test('withAuth false still sends project key but no user token', () async {
    final sdk = client((request) async {
      expect(request.headers['X-Api-Token'], 'project');
      expect(request.headers.keys.map((k) => k.toLowerCase()),
          isNot(contains('authorization')));
      return http.Response('{}', 200);
    }, key: 'project', token: 'user');
    await sdk.post('/products', withAuth: false);
  });

  test('custom API origin leaves public links on project domain', () async {
    final sdk = client((request) async {
      expect(request.url.toString(), 'https://gateway.example.com/v2/products');
      return http.Response('{}', 200);
    }, base: 'https://gateway.example.com/v2/');
    expect(sdk.host, 'https://max.hosteday.com');
    expect(sdk.staticPages['/info/'], 'https://max.hosteday.com/info');
    await sdk.get('/api/products');
  });

  test('foreign REST URLs cannot receive credentials', () async {
    final sdk =
        client((_) async => throw StateError('Must not send'), key: 'secret');
    await expectLater(
        sdk.get('https://other.example/products'), throwsArgumentError);
  });

  for (final status in [429, 430, 431, 432, 433, 500, 503]) {
    test('retains HTTP $status and server message', () async {
      final sdk = client(
          (_) async => http.Response('{"message":"Server detail"}', status));
      await expectLater(
          sdk.get('/products'),
          throwsA(isA<HostedayException>()
              .having((e) => e.statusCode, 'status', status)
              .having((e) => e.displayMessage, 'message', 'Server detail')));
    });
    test('retains HTTP $status for non-JSON error bodies', () async {
      final sdk = client(
          (_) async => http.Response('<html>Unavailable</html>', status));
      await expectLater(
          sdk.get('/products'),
          throwsA(isA<HostedayException>()
              .having((e) => e.statusCode, 'status', status)
              .having((e) => e.response?['raw_body'], 'original body',
                  '<html>Unavailable</html>')));
    });
  }

  test('invalid success JSON retains response status and cause', () async {
    final sdk = client((_) async => http.Response('invalid', 200));
    await expectLater(
        sdk.get('/products'),
        throwsA(isA<HostedayException>()
            .having((e) => e.error, 'cause', isA<FormatException>())));
  });
  test('network error includes transport detail', () async {
    final sdk = client((_) async => throw http.ClientException('offline'));
    await expectLater(
        sdk.get('/products'),
        throwsA(isA<HostedayException>()
            .having((e) => e.message, 'message', contains('offline'))));
  });
  test('timeout has a distinct message', () async {
    final sdk = client((_) async => throw TimeoutException('expired'));
    await expectLater(
        sdk.get('/products'),
        throwsA(isA<HostedayException>()
            .having((e) => e.message, 'message', contains('timed out'))));
  });

  test('public events do not require user auth; private/presence do', () async {
    final sdk = client((request) async {
      expect(request.url.path, '/api/realtime/events/public');
      return http.Response('{}', 200);
    });
    await sdk
        .publishPublicEvent(channel: 'products', event: 'updated', payload: {});
    await expectLater(
        sdk.publishPrivateEvent(
            channel: 'orders', event: 'updated', payload: {}),
        throwsA(isA<HostedayException>()));
    await expectLater(
        sdk.publishPresenceEvent(
            channel: 'orders', event: 'updated', payload: {}),
        throwsA(isA<HostedayException>()));
  });
}
