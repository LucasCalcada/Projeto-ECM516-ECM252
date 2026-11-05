import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/helpers/load_user_data.dart';
import 'package:front_flutter/helpers/user_data_storage.dart';
import 'package:front_flutter/types/account_user.dart';
import 'package:front_flutter/types/api_failure.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

class MemoryPreferences implements SharedPreferencesAsync {
  final values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String tokenWith(Map<String, dynamic> changes) {
  final parts = userToken().split('.');
  final claims = jsonDecode(
    utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
  ) as Map<String, dynamic>;
  claims.addAll(changes);
  parts[1] = base64Url
      .encode(utf8.encode(jsonEncode(claims)))
      .replaceAll('=', '');
  return parts.join('.');
}

Matcher failsWith(ApiFailure failure) => throwsA(
  isA<ApiException>().having((error) => error.failure, 'failure', failure),
);

void main() {
  test('local JSON preserves types and clears only its own key', () async {
    final preferences = MemoryPreferences()..values['language'] = 'pt';
    final storage = LocalUserDataStorage(preferences: preferences);
    final data = {
      'userId': 'user-1',
      'permissions': ['@core:admin'],
      'residencyId': null,
      'iat': 1793600000,
      'exp': 1793603600,
    };
    await storage.saveUserData(data);
    expect(preferences.values['hive.userData'], jsonEncode(data));
    // A new adapter reads the persisted value rather than an instance cache.
    expect(
      await LocalUserDataStorage(preferences: preferences).readUserData(),
      data,
    );
    await storage.clearUserData();
    expect(await storage.readUserData(), isNull);
    expect(preferences.values, {'language': 'pt'});
    for (final invalid in ['not json', '[]']) {
      preferences.values[LocalUserDataStorage.key] = invalid;
      await expectLater(storage.readUserData(), throwsFormatException);
    }
  });

  test('selection persists allowlisted claims and replaces the previous membership', () async {
    final secure = FakeSessionStorage()..token = 'account-token';
    final data = FakeUserDataStorage();
    final member = AccountUser.fromJson(accountUsers.single);
    final first = tokenWith({'residencyId': 'residency-1', 'iat': 1793600000});
    await loadUserData(
      first,
      selectedUser: member,
      sessionStorage: secure,
      userDataStorage: data,
    );
    expect(data.data?['residencyId'], 'residency-1');
    final admin = tokenWith({
      'residencyId': null,
      'residencyName': null,
      'permissions': ['@core:admin'],
      'iat': 1793600010,
      'privateClaim': 'omit',
      'userToken': 'omit',
    });
    final session = await loadUserData(
      admin,
      selectedUser: member,
      sessionStorage: secure,
      userDataStorage: data,
    );
    expect(secure.token, 'account-token');
    expect(secure.userToken, admin);
    expect(data.data, {
      'userId': session.userId,
      'buildingId': session.buildingId,
      'buildingName': session.buildingName,
      'residencyId': null,
      'residencyName': null,
      'permissions': ['@core:admin'],
      'tokenKind': 'user',
      'iat': 1793600010,
      'exp': session.expiresAt.millisecondsSinceEpoch ~/ 1000,
    });
    expect(session.allows(['@complaint:view:building']), isTrue);
  });

  test('invalid or expired tokens cannot write a new session', () async {
    final secure = FakeSessionStorage()..token = 'account-token';
    final data = FakeUserDataStorage();
    for (final (token, failure) in [
      ('malformed', ApiFailure.invalidResponse),
      (tokenWith({'tokenKind': 'account'}), ApiFailure.invalidResponse),
      (tokenWith({'userId': 'another-user'}), ApiFailure.invalidResponse),
      (
        tokenWith({'buildingId': 'another-building'}),
        ApiFailure.invalidResponse,
      ),
      (
        tokenWith({
          'permissions': [42],
        }),
        ApiFailure.invalidResponse,
      ),
      (tokenWith({'residencyId': 42}), ApiFailure.invalidResponse),
      (tokenWith({'exp': 1}), ApiFailure.unauthorized),
    ]) {
      await expectLater(
        loadUserData(
          token,
          selectedUser: AccountUser.fromJson(accountUsers.single),
          sessionStorage: secure,
          userDataStorage: data,
        ),
        failsWith(failure),
      );
    }
    expect(secure.userWrites, 0);
    expect(data.writes, 0);
    expect(secure.token, 'account-token');
  });

  for (final failingStore in ['secure', 'local']) {
    test(
      '$failingStore write failure cleans partial state and allows retry',
      () async {
        final secure = FakeSessionStorage()
          ..token = 'account-token'
          ..userToken = 'old-user-token'
          ..failUserWrite = failingStore == 'secure';
        final data = FakeUserDataStorage()
          ..data = {'userId': 'old-user'}
          ..failWrite = failingStore == 'local';
        Future<void> select() async {
          await loadUserData(
            userToken(),
            selectedUser: AccountUser.fromJson(accountUsers.single),
            sessionStorage: secure,
            userDataStorage: data,
          );
        }

        await expectLater(select(), failsWith(ApiFailure.storage));
        expect(secure.token, 'account-token');
        expect(secure.userToken, isNull);
        expect(data.data, isNull);
        secure.failUserWrite = false;
        data.failWrite = false;
        await select();
        expect(secure.userToken, isNotNull);
        expect(data.data?['userId'], 'user-1');
      },
    );
  }

  test(
    'cleanup still attempts the secure store when local removal fails',
    () async {
      final secure = FakeSessionStorage()
        ..token = 'account-token'
        ..userToken = 'old-user-token';
      final data = FakeUserDataStorage()..failClear = true;
      await expectLater(
        loadUserData(
          userToken(),
          selectedUser: AccountUser.fromJson(accountUsers.single),
          sessionStorage: secure,
          userDataStorage: data,
        ),
        failsWith(ApiFailure.storage),
      );
      expect(secure.userToken, isNull);
      expect(secure.token, 'account-token');
      expect(data.writes, 0);
    },
  );
}
