import 'package:flutter_test/flutter_test.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('sign-in and profile update use fixed API routes and session token',
      () async {
    final paths = <String>[];
    final client = HostedayClient(
      config:
          HostedayConfig.fromOptions({'project_domain': 'max.hosteday.com'}),
      httpClient: MockClient((request) async {
        paths.add(request.url.path);
        if (request.method == 'POST') {
          expect(request.url.path, '/api/auth/login');
          return http.Response(
              '{"token":"user-token","user":{"id":1,"name":"Before","email":"user@example.com"}}',
              200);
        }
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/user');
        expect(request.headers['authorization'], 'Bearer user-token');
        return http.Response(
            '{"data":{"id":1,"name":"After","email":"user@example.com"}}', 200);
      }),
    );
    addTearDown(client.dispose);
    await client.initialize();
    await client.auth.signInWithEmailAndPassword(
        email: 'user@example.com', password: 'Password1!');
    final user = await client.auth.updateProfile(name: 'After');
    expect(user.displayName, 'After');
    expect(paths, ['/api/auth/login', '/api/user']);
  });

  test('auth conversion preserves field validation and response', () {
    final response = <String, dynamic>{
      'message': 'Invalid input',
      'errors': {
        'email': ['Invalid email']
      }
    };
    final error = HostedayAuthException.fromHostedayException(
      HostedayException.fromResponse(response, statusCode: 422),
    );
    expect(error.firstErrorFor('email'), 'Invalid email');
    expect(error.displayMessage, 'Invalid email');
    expect(error.response, response);
    expect(error.code, 'validation-failed');
  });
}
