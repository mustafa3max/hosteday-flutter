import 'package:flutter_test/flutter_test.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

void main() {
  test('builds full uri from baseUrl and path', () {
    const config = HosteDayConfig(
      baseUrl: 'https://example.hosteday.com',
    );

    expect(
      config.uri('/api/user').toString(),
      'https://example.hosteday.com/api/user',
    );
  });
}