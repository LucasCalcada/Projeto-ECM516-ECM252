import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:front_flutter/app.dart';
import 'package:front_flutter/routes/app_routes.dart';
import 'package:front_flutter/views/building_selector.dart';
import 'package:front_flutter/views/home.dart';
import 'package:front_flutter/views/login.dart';
import 'package:front_flutter/views/settings.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fakes.dart';

const _capturePreviews = bool.fromEnvironment('CAPTURE_PREVIEWS');
const _previewKey = Key('preview-boundary');

http.Response jsonResponse(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Future<void> launch(
  WidgetTester tester, {
  FakeSessionStorage? storage,
  FakePreferencesStorage? preferences,
  Future<http.Response> Function(http.Request)? handler,
  String? language = 'pt',
}) async {
  final client = MockClient(
    handler ??
        (request) async {
          switch (request.url.path) {
            case '/auth/login':
              return jsonResponse({'token': 'account-token'});
            case '/account':
              return jsonResponse(accountUsers);
            case '/auth':
              return jsonResponse({'token': userToken()});
            case '/posts':
              return jsonResponse(posts);
            default:
              return jsonResponse({}, 404);
          }
        },
  );
  addTearDown(client.close);
  addTearDown(() async => tester.pumpWidget(const SizedBox()));
  await tester.runAsync(() async {
    await tester.pumpWidget(
      RepaintBoundary(
        key: _previewKey,
        child: HiveApp(
          client: client,
          sessionStorage: storage ?? FakeSessionStorage(),
          preferencesStorage: preferences ?? FakePreferencesStorage(),
          locale: language == null ? null : Locale(language),
        ),
      ),
    );
    // Preferences are read during initState; let the resulting locale load
    // outside the widget tests' fake clock before settling animations.
    await tester.pump();
  });
  await tester.pumpAndSettle();
}

Future<void> login(WidgetTester tester) async {
  await tester.enterText(
    find.byType(TextFormField).at(0),
    'resident@example.test',
  );
  await tester.enterText(find.byType(TextFormField).at(1), 'password');
  await tester.ensureVisible(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
}

Future<void> selectBuilding(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const ValueKey('building-user-1')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('building-user-1')));
  await tester.pumpAndSettle();
}

Future<void> openMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

Future<void> openSettings(WidgetTester tester) async {
  await openMenu(tester);
  final settings = find.byKey(const ValueKey('menu-/settings'));
  await tester.ensureVisible(settings);
  await tester.pumpAndSettle();
  await tester.tap(settings);
  await tester.pumpAndSettle();
}

Future<void> preview(WidgetTester tester, String name) async {
  if (!_capturePreviews) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_previewKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void mobileSize(WidgetTester tester, Size size, {double textScale = 1}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final language in ['pt', 'en', 'es']) {
      await rootBundle.loadString('lib/lang/$language/login.json');
      await rootBundle.loadString('lib/lang/$language/app.json');
      await GlobalMaterialLocalizations.delegate.load(Locale(language));
      await GlobalCupertinoLocalizations.delegate.load(Locale(language));
    }
    // Optional local QA images use a real font instead of Flutter tests' Ahem.
    if (_capturePreviews && Platform.isWindows) {
      final font = FontLoader('Roboto')
        ..addFont(
          File('C:/Windows/Fonts/segoeui.ttf')
              .readAsBytes()
              .then((bytes) => ByteData.sublistView(bytes)),
        );
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });

  testWidgets(
    'login, membership, home, settings, back and logout preserve correct session boundaries',
    (tester) async {
      mobileSize(tester, const Size(390, 844));
      final storage = FakeSessionStorage();
      final preferences = FakePreferencesStorage();
      await launch(tester, storage: storage, preferences: preferences);
      await login(tester);
      expect(find.byType(BuildingSelector), findsOneWidget);
      await preview(tester, 'building-selector');
      await selectBuilding(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(storage.userToken, isNotNull);
      expect(find.text('Manutenção dos elevadores'), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(HomeScreen))).canPop(),
        isFalse,
      );
      await preview(tester, 'home');

      await openMenu(tester);
      final residents = tester.widget<ListTile>(
        find.byKey(const ValueKey('menu-/residents')),
      );
      final reservations = tester.widget<ListTile>(
        find.byKey(const ValueKey('menu-/reservations')),
      );
      expect(residents.enabled, isFalse);
      expect(
        residents.subtitle,
        isA<Text>().having(
          (text) => text.data,
          'permission',
          contains('permissão'),
        ),
      );
      expect(reservations.enabled, isFalse);
      expect(
        reservations.subtitle,
        isA<Text>().having(
          (text) => text.data,
          'availability',
          contains('Em breve'),
        ),
      );
      await preview(tester, 'menu');
      await tester.ensureVisible(find.byKey(const ValueKey('menu-/settings')));
      await tester.tap(find.byKey(const ValueKey('menu-/settings')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('language-en')));
      await tester.runAsync(() async => tester.pump());
      await tester.pumpAndSettle();
      expect(preferences.language, 'en');
      expect(find.text('Settings'), findsOneWidget);
      await preview(tester, 'settings');

      Navigator.of(tester.element(find.byType(SettingsScreen))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      await openMenu(tester);
      await tester.ensureVisible(find.byKey(const Key('menu-sign-out')));
      await tester.tap(find.byKey(const Key('menu-sign-out')));
      await tester.pumpAndSettle();
      expect(find.byType(Login), findsOneWidget);
      expect(storage.token, isNull);
      expect(storage.userToken, isNull);
      expect(preferences.language, 'en');
      expect(
        Navigator.of(tester.element(find.byType(Login))).canPop(),
        isFalse,
      );

      await tester.pumpWidget(const SizedBox());
      await launch(
        tester,
        storage: storage,
        preferences: preferences,
        language: null,
      );
      expect(
        Localizations.localeOf(tester.element(find.byType(Login))).languageCode,
        'en',
      );
    },
  );

  testWidgets(
    'selection prevents duplicates and waits for user-token persistence',
    (tester) async {
      final storage = FakeSessionStorage()
        ..pendingUserWrite = Completer<void>();
      var selections = 0;
      await launch(
        tester,
        storage: storage,
        handler: (request) async {
          if (request.url.path == '/auth/login') {
            return jsonResponse({'token': 'account-token'});
          }
          if (request.url.path == '/account') return jsonResponse(accountUsers);
          if (request.url.path == '/auth') {
            selections++;
            return jsonResponse({'token': userToken()});
          }
          return jsonResponse([]);
        },
      );
      await login(tester);
      final item = find.byKey(const ValueKey('building-user-1'));
      await tester.tap(item);
      await tester.pump();
      await tester.tap(item);
      await tester.pump();
      expect(selections, 1);
      expect(find.byType(HomeScreen), findsNothing);
      storage.pendingUserWrite!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'storage failure during selection permits retry without entering home',
    (tester) async {
      final storage = FakeSessionStorage()..failUserWrite = true;
      await launch(tester, storage: storage);
      await login(tester);
      await selectBuilding(tester);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.textContaining('Não foi possível salvar'), findsOneWidget);
      storage.failUserWrite = false;
      await selectBuilding(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('protected routes cannot bypass login or membership selection', (
    tester,
  ) async {
    await launch(tester);
    Navigator.of(tester.element(find.byType(Login))).pushNamed(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsNothing);
    await login(tester);
    Navigator.of(tester.element(find.byType(BuildingSelector)))
        .pushNamed(AppRoutes.settings);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.byType(BuildingSelector), findsOneWidget);
  });

  testWidgets('failed refresh keeps existing posts and retry recovers', (
    tester,
  ) async {
    var reads = 0;
    await launch(
      tester,
      handler: (request) async {
        if (request.url.path == '/auth/login') {
          return jsonResponse({'token': 'account-token'});
        }
        if (request.url.path == '/account') return jsonResponse(accountUsers);
        if (request.url.path == '/auth') {
          return jsonResponse({'token': userToken()});
        }
        reads++;
        if (reads == 2) throw http.ClientException('offline');
        return jsonResponse(posts);
      },
    );
    await login(tester);
    await selectBuilding(tester);
    await tester.tap(find.byKey(const Key('refresh-home')));
    await tester.pumpAndSettle();
    expect(find.text('Manutenção dos elevadores'), findsOneWidget);
    expect(
      find.text('Não foi possível conectar. Verifique sua conexão.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(reads, 3);
    expect(
      find.text('Não foi possível conectar. Verifique sua conexão.'),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox());
  });

  for (final endpoint in ['/account', '/posts']) {
    testWidgets('401 at $endpoint clears session and returns to login', (
      tester,
    ) async {
      final storage = FakeSessionStorage();
      await launch(
        tester,
        storage: storage,
        handler: (request) async {
          if (request.url.path == endpoint) return jsonResponse({}, 401);
          if (request.url.path == '/auth/login') {
            return jsonResponse({'token': 'account-token'});
          }
          if (request.url.path == '/account') return jsonResponse(accountUsers);
          return jsonResponse({'token': userToken()});
        },
      );
      await login(tester);
      if (endpoint == '/posts') await selectBuilding(tester);
      expect(find.byType(Login), findsOneWidget);
      expect(storage.token, isNull);
      expect(storage.userToken, isNull);
      expect(find.text('Sua sessão expirou. Entre novamente.'), findsOneWidget);
    });
  }

  testWidgets('empty membership list offers feedback and sign out', (
    tester,
  ) async {
    await launch(
      tester,
      handler: (request) async => request.url.path == '/auth/login'
          ? jsonResponse({'token': 'account-token'})
          : jsonResponse([]),
    );
    await login(tester);
    expect(
      find.text('Sua conta ainda não possui vínculos com um condomínio.'),
      findsOneWidget,
    );
    expect(find.text('Sair'), findsOneWidget);
  });

  testWidgets(
    'empty posts show both empty sections and refresh remains available',
    (tester) async {
      await launch(
        tester,
        handler: (request) async {
          if (request.url.path == '/auth/login') {
            return jsonResponse({'token': 'account-token'});
          }
          if (request.url.path == '/account') return jsonResponse(accountUsers);
          if (request.url.path == '/auth') {
            return jsonResponse({'token': userToken()});
          }
          return jsonResponse([]);
        },
      );
      await login(tester);
      await selectBuilding(tester);
      expect(find.text('Não há novos avisos.'), findsOneWidget);
      expect(find.text('Não há novos eventos.'), findsOneWidget);
      expect(find.byKey(const Key('refresh-home')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('preference write failure retains the previous language', (
    tester,
  ) async {
    final preferences = FakePreferencesStorage()..failWrite = true;
    await launch(tester, preferences: preferences);
    await login(tester);
    await selectBuilding(tester);
    await openSettings(tester);
    await tester.tap(find.byKey(const ValueKey('language-en')));
    await tester.pumpAndSettle();
    expect(find.text('Configurações'), findsOneWidget);
    expect(find.textContaining('Não foi possível salvar'), findsOneWidget);
    expect(preferences.language, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final language in ['pt', 'en', 'es']) {
    testWidgets('$language main flow fits 320px with double text size', (
      tester,
    ) async {
      mobileSize(tester, const Size(320, 568), textScale: 2);
      await launch(tester, language: language);
      await login(tester);
      expect(tester.takeException(), isNull);
      await selectBuilding(tester);
      expect(tester.takeException(), isNull);
      await preview(tester, 'home-small-$language');
      final scroll = find.byType(CustomScrollView);
      await tester.drag(scroll, const Offset(0, -450));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await openSettings(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('language-es')),
        100,
        scrollable: find.descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Scrollable),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
