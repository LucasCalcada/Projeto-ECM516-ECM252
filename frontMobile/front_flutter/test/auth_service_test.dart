import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/helpers/auth_service.dart';
import 'package:front_flutter/types/auth_result.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('posts the existing API contract and preserves the password', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.toString(), 'https://example.test/api/auth/login');
      expect(request.headers['Content-Type'], 'application/json');
      expect(jsonDecode(request.body), {
        'email': 'resident@example.test',
        'password': ' password with spaces ',
      });
      return http.Response('{"token":"account-token"}', 200);
    });
    addTearDown(client.close);
    final service = AuthService(
      client: client,
      baseUrl: 'https://example.test/api/',
    );

    final result = await service.login(
      email: 'resident@example.test',
      password: ' password with spaces ',
    );

    expect(result.token, 'account-token');
  });

  for (final entry in {
    400: AuthFailure.invalidRequest,
    401: AuthFailure.invalidCredentials,
    403: AuthFailure.invalidResponse,
    429: AuthFailure.invalidResponse,
    500: AuthFailure.server,
    503: AuthFailure.server,
  }.entries) {
    test('maps HTTP ${entry.key} without exposing the response body', () async {
      final client = MockClient(
        (_) async => http.Response('internal details', entry.key),
      );
      addTearDown(client.close);
      final service = AuthService(
        client: client,
        baseUrl: 'https://example.test',
      );
      await expectLater(
        service.login(email: 'user', password: 'password'),
        throwsA(
          isA<AuthException>().having((e) => e.failure, 'failure', entry.value),
        ),
      );
    });
  }

  for (final body in [
    'not json',
    '{}',
    'null',
    '[]',
    '{"token":null}',
    '{"token":42}',
    '{"token":"  "}',
  ]) {
    test('rejects malformed success response $body', () async {
      final client = MockClient((_) async => http.Response(body, 200));
      addTearDown(client.close);
      final service = AuthService(
        client: client,
        baseUrl: 'https://example.test',
      );
      await expectLater(
        service.login(email: 'user', password: 'password'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.invalidResponse,
          ),
        ),
      );
    });
  }

  test('reports a network failure', () async {
    final client = MockClient(
      (_) async => throw http.ClientException('offline'),
    );
    addTearDown(client.close);
    final service = AuthService(
      client: client,
      baseUrl: 'https://example.test',
    );
    await expectLater(
      service.login(email: 'user', password: 'password'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.failure,
          'failure',
          AuthFailure.network,
        ),
      ),
    );
  });

  test('limits waiting time and does not retry the credentials', () async {
    var requests = 0;
    final pending = Completer<http.Response>();
    final client = MockClient((_) {
      requests++;
      return pending.future;
    });
    addTearDown(client.close);
    final service = AuthService(
      client: client,
      baseUrl: 'https://example.test',
      timeout: const Duration(milliseconds: 10),
    );
    await expectLater(
      service.login(email: 'user', password: 'password'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.failure,
          'failure',
          AuthFailure.timeout,
        ),
      ),
    );
    expect(requests, 1);
    pending.complete(http.Response('{"token":"late-token"}', 200));
  });
}
