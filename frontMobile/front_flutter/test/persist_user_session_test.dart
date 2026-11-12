import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/helpers/persist_user_session.dart';
import 'package:front_flutter/helpers/session_storage.dart';
import 'package:front_flutter/types/account_user.dart';
import 'package:front_flutter/types/api_failure.dart';
import 'support/fakes.dart';

void main() {
  test('selection saves only the token and clears the previous section', () async {
    final storage = FakeSessionStorage()
      ..token = 'account-token'
      ..section = const SessionSection(userId: 'old', buildingId: 'old', route: '/settings');
    final token = userToken();
    final session = await persistUserSession(token,
      selectedUser: AccountUser.fromJson(accountUsers.single), sessionStorage: storage);
    expect(storage.userToken, token);
    expect(storage.token, 'account-token');
    expect(storage.section, isNull);
    expect(session.userId, 'user-1');
  });

  test('write failure clears partial user state and permits retry', () async {
    final storage = FakeSessionStorage()..token = 'account-token'..failUserWrite = true;
    Future<void> select() async {
      await persistUserSession(userToken(),
        selectedUser: AccountUser.fromJson(accountUsers.single), sessionStorage: storage);
    }
    await expectLater(select(), throwsA(isA<ApiException>().having((e) => e.failure, 'failure', ApiFailure.storage)));
    expect(storage.token, 'account-token');
    expect(storage.userToken, isNull);
    storage.failUserWrite = false;
    await select();
    expect(storage.userToken, isNotNull);
  });
}
