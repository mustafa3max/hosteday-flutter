import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const hostedayRecord = {
    'id': 1,
    'name': 'Product',
    'price': '3377.87',
    'is_active': 1,
    'disabled': 0,
    'image': null,
  };
  Map<String, dynamic> hostedayEnvelope() => {
        'success': true,
        'message': null,
        'data': {
          'current_page': 1,
          'data': [hostedayRecord],
          'per_page': 15,
          'next_page_url': null,
          'prev_page_url': null,
          'from': 1,
          'to': 1,
        },
      };

  HostedayClient hostedayClient(
    Future<http.Response> Function(http.Request) handler, {
    String? token,
    String? base,
  }) {
    final hosteday = HostedayClient(
      config: HostedayConfig.fromOptions({
        HostedayOptionKeys.projectDomain: 'max.hosteday.com/api',
        HostedayOptionKeys.projectApiKey: 'project-key',
        if (base != null) HostedayOptionKeys.apiBaseUrl: base,
      }),
      tokenProvider: StaticHostedayTokenProvider(token),
      httpClient: MockClient(handler),
    );
    addTearDown(hosteday.dispose);
    return hosteday;
  }

  HostedayClient hostedayResponse(Object? body, {int status = 200}) =>
      hostedayClient((_) async => http.Response(jsonEncode(body), status));

  test('index unwraps records and preserves original values', () async {
    final hosteday = hostedayResponse(hostedayEnvelope());
    final hostedayPage = await hosteday.index('products');
    expect(hostedayPage.items, [hostedayRecord]);
    expect(hostedayPage.currentPage, 1);
    expect(hostedayPage.perPage, 15);
    expect(hostedayPage.from, 1);
    expect(hostedayPage.to, 1);
    expect(hostedayPage.total, isNull);
    expect(hostedayPage.lastPage, isNull);
    expect(hostedayPage.nextPageUrl, isNull);
    expect(hostedayPage.previousPageUrl, isNull);
    expect(hostedayPage.hasNextPage, isFalse);
    expect(hostedayPage.hasPreviousPage, isFalse);
  });

  test('empty page and nullable optional fields are valid', () async {
    final hostedayBody = hostedayEnvelope();
    hostedayBody['data'].addAll({
      'data': [],
      'from': null,
      'to': null,
      'total': null,
      'last_page': null,
    });
    final hostedayPage = await hostedayResponse(hostedayBody).index('anything');
    expect(hostedayPage.items, isEmpty);
    expect(hostedayPage.from, isNull);
    expect(hostedayPage.to, isNull);
    expect(hostedayPage.total, isNull);
    expect(hostedayPage.lastPage, isNull);
  });

  test('metadata is server supplied; links are never followed', () async {
    var hostedayCalls = 0;
    final hostedayBody = hostedayEnvelope();
    hostedayBody['data'].addAll({
      'current_page': 2,
      'next_page_url': 'http://other.example/api/products?page=3',
      'prev_page_url': 'http://other.example/api/products?page=1',
      'total': 100,
      'last_page': 7,
    });
    final hosteday = hostedayClient((request) async {
      hostedayCalls++;
      expect(request.url.origin, 'https://gateway.example.com');
      expect(request.url.path, '/v2/products');
      expect(request.url.queryParameters['page'], '${hostedayCalls + 1}');
      return http.Response(jsonEncode(hostedayBody), 200);
    }, base: 'https://gateway.example.com/v2');
    final hostedayPage = await hosteday.index('/api/products', page: 2);
    expect(hostedayCalls, 1);
    expect(hostedayPage.total, 100);
    expect(hostedayPage.lastPage, 7);
    expect(hostedayPage.hasNextPage, isTrue);
    expect(hostedayPage.hasPreviousPage, isTrue);
    expect(
      hostedayPage.previousPageUrl,
      'http://other.example/api/products?page=1',
    );
    await hosteday.index('products', page: hostedayPage.currentPage + 1);
    expect(hostedayCalls, 2);
  });

  for (final hostedayPath in ['products', '/products', '/api/products']) {
    for (final hostedayAuth in [true, false]) {
      test('index/show paths and auth: $hostedayPath $hostedayAuth', () async {
        final hosteday = hostedayClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.origin, 'https://max.hosteday.com');
          expect(
            request.headers['authorization'],
            hostedayAuth ? 'Bearer user-token' : isNull,
          );
          expect(request.headers['X-Api-Token'], 'project-key');
          expect(request.headers['X-Custom'], 'custom');
          expect(request.url.queryParameters['relation_field'], 'category_id');
          expect(request.url.queryParameters['relation_value'], '5');
          expect(request.url.queryParameters['search'], 'phone');
          expect(request.url.queryParameters['sort'], 'name');
          if (request.url.pathSegments.last == 'a/b') {
            expect(request.url.pathSegments, ['api', 'products', 'a/b']);
            return http.Response(
              jsonEncode({
                'success': true,
                'message': null,
                'data': hostedayRecord,
              }),
              200,
            );
          }
          expect(request.url.path, '/api/products');
          expect(request.url.queryParameters['page'], '2');
          expect(request.url.queryParametersAll['filters[status][]'], [
            'active',
            'pending',
          ]);
          return http.Response(jsonEncode(hostedayEnvelope()), 200);
        }, token: 'user-token');
        await hosteday.index(
          '$hostedayPath?sort=name',
          page: 2,
          search: 'phone',
          filters: {
            'status': ['active', 'pending'],
          },
          relationField: 'category_id',
          relationValue: 5,
          queryParameters: {'page': 99},
          withAuth: hostedayAuth,
          headers: {'X-Custom': 'custom'},
        );
        final hostedayProduct = await hosteday.show(
          hostedayPath,
          id: 'a/b',
          search: 'phone',
          relationField: 'category_id',
          relationValue: 5,
          queryParameters: {'sort': 'name'},
          withAuth: hostedayAuth,
          headers: {'X-Custom': 'custom'},
        );
        expect(hostedayProduct, hostedayRecord);
      });
    }
  }

  for (final hostedayOperation in ['index', 'show']) {
    Future<Object> hostedayRead(
      HostedayClient hosteday, {
      bool auth = false,
      Duration? timeout,
    }) =>
        hostedayOperation == 'index'
            ? hosteday.index('products', withAuth: auth, timeout: timeout)
            : hosteday.show('products',
                id: 1, withAuth: auth, timeout: timeout);

    for (final hostedayBody in [
      {},
      {'success': 'true', 'data': {}},
      {'success': true},
      {'success': true, 'data': null},
      {'success': true, 'data': []},
      {'success': true, 'data': 'wrong'},
    ]) {
      test(
        '$hostedayOperation rejects malformed envelope $hostedayBody',
        () async {
          await expectLater(
            hostedayRead(hostedayResponse(hostedayBody)),
            throwsA(
              isA<HostedayException>().having(
                (e) => e.response,
                'body',
                hostedayBody,
              ),
            ),
          );
        },
      );
    }
    for (final hostedayStatus in [200, 422, 500]) {
      test(
        '$hostedayOperation retains server failure $hostedayStatus',
        () async {
          final hostedayBody = {
            'success': false,
            'message': 'Server detail',
            'errors': {
              'name': ['Required'],
            },
            'data': null,
          };
          await expectLater(
            hostedayRead(
              hostedayResponse(hostedayBody, status: hostedayStatus),
            ),
            throwsA(
              isA<HostedayException>()
                  .having(
                    (e) => e.message,
                    'message',
                    contains('Server detail'),
                  )
                  .having((e) => e.response, 'body', hostedayBody)
                  .having(
                    (e) => e.firstErrorFor('name'),
                    'validation',
                    'Required',
                  )
                  .having(
                    (e) => e.statusCode,
                    'HTTP status',
                    hostedayStatus == 200 ? null : hostedayStatus,
                  ),
            ),
          );
        },
      );
    }
    test('$hostedayOperation requires token when authenticated', () async {
      final hosteday = hostedayClient(
        (_) async => throw StateError('Must not send'),
      );
      await expectLater(
        hostedayRead(hosteday, auth: true),
        throwsA(
          isA<HostedayException>().having((e) => e.statusCode, 'status', 401),
        ),
      );
    });
    test('$hostedayOperation forwards timeout', () async {
      final hosteday = hostedayClient((_) => Completer<http.Response>().future);
      await expectLater(
        hostedayRead(hosteday, timeout: const Duration(milliseconds: 5)),
        throwsA(
          isA<HostedayException>().having(
            (e) => e.error,
            'cause',
            isA<TimeoutException>(),
          ),
        ),
      );
    });
  }

  for (final hostedayEntry in <String, Object?>{
    'data': [1],
    'current_page': '1',
    'per_page': null,
    'next_page_url': 3,
    'prev_page_url': '',
    'from': '1',
    'to': false,
    'total': '100',
    'last_page': 1.5,
  }.entries) {
    test('index rejects malformed ${hostedayEntry.key}', () async {
      final hostedayBody = hostedayEnvelope();
      hostedayBody['message'] = 'Server context';
      hostedayBody['data'][hostedayEntry.key] = hostedayEntry.value;
      await expectLater(
        hostedayResponse(hostedayBody).index('products'),
        throwsA(
          isA<HostedayException>()
              .having((e) => e.message, 'field', contains(hostedayEntry.key))
              .having((e) => e.message, 'message', contains('Server context')),
        ),
      );
    });
  }

  test('index rejects missing list and invalid page before sending', () async {
    final hostedayBody = hostedayEnvelope();
    hostedayBody['data'].remove('data');
    await expectLater(
      hostedayResponse(hostedayBody).index('products'),
      throwsA(isA<HostedayException>()),
    );
    final hosteday = hostedayClient(
      (_) async => throw StateError('Must not send'),
    );
    await expectLater(hosteday.index('products', page: 0), throwsArgumentError);
  });

  test(
    'get still returns full envelopes including application failures',
    () async {
      for (final hostedayBody in [
        hostedayEnvelope(),
        {'success': false, 'data': null},
      ]) {
        expect(
          await hostedayResponse(hostedayBody).get('products'),
          hostedayBody,
        );
      }
    },
  );
}
