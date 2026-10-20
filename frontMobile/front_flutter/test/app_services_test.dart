import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/helpers/api_client.dart';
import 'package:front_flutter/helpers/communication_service.dart';
import 'package:front_flutter/helpers/core_service.dart';
import 'package:front_flutter/types/account_user.dart';
import 'package:front_flutter/types/api_failure.dart';
import 'package:front_flutter/types/user_session.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fakes.dart';

Matcher failsWith(ApiFailure failure) => throwsA(
  isA<ApiException>().having((error) => error.failure, 'failure', failure),
);

ApiClient api(Future<http.Response> Function(http.Request) handler) {
  final client = MockClient(handler);
  addTearDown(client.close);
  return ApiClient(client: client, baseUrl: 'https://example.test/');
}

void main() {
  test(
    'account listing and selection use the account token and selected ID',
    () async {
      final requests = <http.Request>[];
      final token = userToken();
      final core = CoreService(
        api((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode(
              request.url.path == '/account' ? accountUsers : {'token': token},
            ),
            200,
          );
        }),
      );
      final users = await core.listUsers('account-token');
      final session = await core.selectUser('account-token', users.single);
      expect(requests.map((r) => r.url.path), ['/account', '/auth']);
      expect(
        requests.every(
          (r) => r.headers['Authorization'] == 'Bearer account-token',
        ),
        isTrue,
      );
      expect(requests.last.url.queryParameters, {'userId': 'user-1'});
      expect(session.token, token);
      expect(session.buildingName, accountUsers.single['buildingName']);
      expect(session.residencyName, 'Apartamento 204');
    },
  );

  test(
    'selection rejects account tokens, mismatched users and expired tokens',
    () async {
      for (final (token, failure) in [
        (userToken(tokenKind: 'account'), ApiFailure.invalidResponse),
        (userToken(userId: 'other-user'), ApiFailure.invalidResponse),
        (
          userToken(
            expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
          ),
          ApiFailure.unauthorized,
        ),
      ]) {
        final service = CoreService(
          api((_) async => http.Response(jsonEncode({'token': token}), 200)),
        );
        await expectLater(
          service.selectUser(
            'account-token',
            AccountUser.fromJson(accountUsers.single),
          ),
          failsWith(failure),
        );
      }
    },
  );

  test(
    'posts use the user token and preserve order and date instants',
    () async {
      final session = UserSession.fromToken(userToken());
      final service = CommunicationService(
        api((request) async {
          expect(request.url.path, '/posts');
          expect(request.headers['Authorization'], 'Bearer ${session.token}');
          return http.Response.bytes(utf8.encode(jsonEncode(posts)), 200);
        }),
      );
      final result = await service.listPosts(session);
      expect(result.map((post) => post.id), ['notice-1', 'event-1']);
      expect(result.first.eventAt, isNull);
      expect(
        result.last.eventAt!.isAtSameMomentAs(
          DateTime.parse('2026-10-25T21:00:00Z'),
        ),
        isTrue,
      );
      expect(result.last.eventAt!.isUtc, isFalse);
    },
  );

  test('expired session does not issue a posts request', () async {
    var requests = 0;
    final service = CommunicationService(
      api((_) async {
        requests++;
        return http.Response('[]', 200);
      }),
    );
    await expectLater(
      service.listPosts(
        UserSession.fromToken(
          userToken(
            expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
          ),
        ),
      ),
      failsWith(ApiFailure.unauthorized),
    );
    expect(requests, 0);
  });

  test(
    'permission checks accept any matching grant and the admin override',
    () {
      final session = UserSession.fromToken(userToken());
      expect(session.allows([]), isTrue);
      expect(
        session.allows(['@reservation:view:building', '@reservation:create']),
        isTrue,
      );
      expect(session.allows(['@core:user:manage']), isFalse);
      expect(
        UserSession.fromToken(userToken(permissions: ['@core:admin']))
            .allows(['@core:user:manage']),
        isTrue,
      );
    },
  );

  for (final entry in {
    401: ApiFailure.unauthorized,
    403: ApiFailure.forbidden,
    500: ApiFailure.server,
    404: ApiFailure.invalidResponse,
  }.entries) {
    test(
      'HTTP ${entry.key} is classified without exposing response bodies',
      () async {
        await expectLater(
          api((_) async => http.Response('private detail', entry.key))
              .get('/posts', token: 'token'),
          failsWith(entry.value),
        );
      },
    );
  }

  test(
    'offline, timeout and malformed response produce actionable failures',
    () async {
      await expectLater(
        api((_) async => throw http.ClientException('offline'))
            .get('/posts', token: 'token'),
        failsWith(ApiFailure.network),
      );
      await expectLater(
        api((_) async => throw TimeoutException('slow'))
            .get('/posts', token: 'token'),
        failsWith(ApiFailure.timeout),
      );
      await expectLater(
        api((_) async => http.Response('not json', 200))
            .get('/posts', token: 'token'),
        failsWith(ApiFailure.invalidResponse),
      );
      final service = CommunicationService(
        api((_) async => http.Response('[{"id":4}]', 200)),
      );
      await expectLater(
        service.listPosts(UserSession.fromToken(userToken())),
        failsWith(ApiFailure.invalidResponse),
      );
    },
  );
}
