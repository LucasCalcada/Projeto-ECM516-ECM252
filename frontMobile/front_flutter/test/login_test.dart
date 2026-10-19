import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/app.dart';
import 'package:front_flutter/helpers/auth_service.dart';
import 'package:front_flutter/helpers/session_storage.dart';
import 'package:front_flutter/routes/app_routes.dart';
import 'package:front_flutter/views/account_session.dart';
import 'package:front_flutter/views/login.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeSessionStorage implements SessionStorage {
  String? token;
  int writes = 0;
  bool failWrite = false;
  bool failClear = false;
  Completer<void>? pendingWrite;

  @override
  Future<void> saveAccountToken(String value) async {
    writes++;
    if (failWrite) throw StateError('storage unavailable');
    if (pendingWrite != null) await pendingWrite!.future;
    token = value;
  }

  @override
  Future<String?> readAccountToken() async => token;

  @override
  Future<void> clearSession() async {
    if (failClear) throw StateError('storage unavailable');
    token = null;
  }
}

Finder input(String key) => find.descendant(
  of: find.byKey(Key(key)),
  matching: find.byType(TextFormField),
);
Finder get submitButton => find.descendant(
  of: find.byKey(const Key('login-submit')),
  matching: find.byType(ElevatedButton),
);

Future<void> enterCredentials(WidgetTester tester) async {
  await tester.enterText(input('login-email'), 'resident@example.test');
  await tester.enterText(input('login-password'), ' secret ');
}

Future<void> submit(WidgetTester tester) async {
  await tester.ensureVisible(submitButton);
  await tester.tap(submitButton);
  await tester.pump();
}

Future<void> mount(
  WidgetTester tester,
  MockClient client,
  FakeSessionStorage storage, {
  String locale = 'pt',
}) async {
  addTearDown(client.close);
  await tester.runAsync(() async {
    await tester.pumpWidget(
      HiveApp(
        authService: AuthService(
          client: client,
          baseUrl: 'https://example.test',
        ),
        sessionStorage: storage,
        locale: Locale(locale),
      ),
    );
  });
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Asset IO runs outside the fake clock used by widget tests.
  setUpAll(() async {
    for (final language in ['pt', 'en', 'es']) {
      await rootBundle.loadString('lib/lang/$language/login.json');
    }
  });

  testWidgets('empty fields do not send credentials', (tester) async {
    var requests = 0;
    final storage = FakeSessionStorage();
    await mount(
      tester,
      MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
      storage,
    );
    await submit(tester);
    await tester.pumpAndSettle();
    expect(find.text('Informe seu email.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    expect(requests, 0);
    expect(storage.writes, 0);
  });

  testWidgets('password is hidden and can be revealed without clearing it', (
    tester,
  ) async {
    await mount(
      tester,
      MockClient((_) async => http.Response('{}', 200)),
      FakeSessionStorage(),
    );
    await enterCredentials(tester);
    final passwordField = find.descendant(
      of: input('login-password'),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(passwordField).obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();
    expect(tester.widget<EditableText>(passwordField).obscureText, isFalse);
    expect(
      tester.widget<EditableText>(passwordField).controller.text,
      ' secret ',
    );
  });

  testWidgets(
    'blocks duplicate submissions, waits for storage, then signs out',
    (tester) async {
      var requests = 0;
      final response = Completer<http.Response>();
      final storage = FakeSessionStorage()..pendingWrite = Completer<void>();
      await mount(
        tester,
        MockClient((_) {
          requests++;
          return response.future;
        }),
        storage,
      );
      await enterCredentials(tester);
      await submit(tester);
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNull);
      await tester.tap(submitButton);
      await tester.pump();
      expect(requests, 1);
      expect(find.text('Entrando...'), findsOneWidget);

      response.complete(http.Response('{"token":"account-token"}', 200));
      await tester.pump();
      expect(find.byType(AccountSession), findsNothing);
      storage.pendingWrite!.complete();
      await tester.pumpAndSettle();
      expect(storage.token, 'account-token');
      expect(find.text('Login realizado'), findsOneWidget);
      expect(find.byType(Login), findsNothing);
      expect(
        Navigator.of(tester.element(find.byType(AccountSession))).canPop(),
        isFalse,
      );

      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();
      expect(storage.token, isNull);
      expect(find.byType(Login), findsOneWidget);
      expect(find.byType(AccountSession), findsNothing);
      expect(
        tester.widget<TextFormField>(input('login-password')).controller!.text,
        isEmpty,
      );
    },
  );

  testWidgets('incorrect credentials allow retry without storing a session', (
    tester,
  ) async {
    var requests = 0;
    final storage = FakeSessionStorage();
    await mount(
      tester,
      MockClient((_) async {
        requests++;
        return requests == 1
            ? http.Response('{"message":"Unauthorized"}', 401)
            : http.Response('{"token":"account-token"}', 200);
      }),
      storage,
    );
    await enterCredentials(tester);
    await submit(tester);
    await tester.pumpAndSettle();
    expect(find.text('Email ou senha incorretos.'), findsOneWidget);
    expect(storage.writes, 0);
    expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNotNull);
    await submit(tester);
    await tester.pumpAndSettle();
    expect(find.byType(AccountSession), findsOneWidget);
  });

  testWidgets('storage failure keeps the user on login', (tester) async {
    final storage = FakeSessionStorage()..failWrite = true;
    await mount(
      tester,
      MockClient((_) async => http.Response('{"token":"account-token"}', 200)),
      storage,
    );
    await enterCredentials(tester);
    await submit(tester);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Não foi possível atualizar a sessão neste dispositivo. Tente novamente.',
      ),
      findsOneWidget,
    );
    expect(find.byType(AccountSession), findsNothing);
    expect(storage.token, isNull);
  });

  testWidgets('network failure shows translated feedback and permits retry', (
    tester,
  ) async {
    final storage = FakeSessionStorage();
    await mount(
      tester,
      MockClient((_) async => throw http.ClientException('offline')),
      storage,
      locale: 'en',
    );
    await enterCredentials(tester);
    await submit(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('Could not connect to the server. Check your connection.'),
      findsOneWidget,
    );
    expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNotNull);
    expect(storage.writes, 0);
  });

  testWidgets('keyboard done submits the form', (tester) async {
    final storage = FakeSessionStorage();
    await mount(
      tester,
      MockClient((_) async => http.Response('{"token":"account-token"}', 200)),
      storage,
    );
    await enterCredentials(tester);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(AccountSession), findsOneWidget);
  });

  testWidgets(
    'late network response does not persist or navigate after disposal',
    (tester) async {
      final response = Completer<http.Response>();
      final storage = FakeSessionStorage();
      await mount(tester, MockClient((_) => response.future), storage);
      await enterCredentials(tester);
      await submit(tester);
      await tester.pumpWidget(const SizedBox());
      response.complete(http.Response('{"token":"account-token"}', 200));
      await tester.pumpAndSettle();
      expect(storage.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('account route requires a completed login in this app session', (
    tester,
  ) async {
    await mount(
      tester,
      MockClient((_) async => http.Response('{}', 200)),
      FakeSessionStorage(),
    );
    Navigator.of(tester.element(find.byType(Login)))
        .pushNamed(AppRoutes.account);
    await tester.pumpAndSettle();
    expect(find.byType(AccountSession), findsNothing);
    expect(find.byType(Login), findsOneWidget);
  });

  for (final language in ['pt', 'en', 'es']) {
    testWidgets('$language fits a small display with keyboard and large text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await mount(
        tester,
        MockClient((_) async => http.Response('{}', 200)),
        FakeSessionStorage(),
        locale: language,
      );
      await submit(tester);
      await tester.pumpAndSettle();
      await tester.ensureVisible(submitButton);
      expect(tester.takeException(), isNull);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(submitButton.hitTestable(), findsOneWidget);
    });
  }
}
