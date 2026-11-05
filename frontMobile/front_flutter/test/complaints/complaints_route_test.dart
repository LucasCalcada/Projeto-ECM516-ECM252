import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/app.dart';
import 'package:front_flutter/features/complaints/presentation/complaints_screen.dart';
import 'package:front_flutter/views/home.dart';
import 'package:front_flutter/views/login.dart';
import 'package:front_flutter/views/settings.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/fakes.dart';

const _capture = bool.fromEnvironment('CAPTURE_COMPLAINT_PREVIEWS');
const _boundary = Key('complaint-route-preview');

String _token({bool manager = false, bool resident = true}) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'HS256'})}.${encode({
    'tokenKind': 'user',
    'userId': 'user-1',
    'buildingId': 'building-1',
    'buildingName': 'Condomínio QA',
    if (resident) 'residencyId': 'residence-1',
    'permissions': manager ? ['@core:admin'] : ['@complaint:create', '@complaint:view:residency'],
    'exp': DateTime.utc(2100).millisecondsSinceEpoch ~/ 1000,
  })}.synthetic-signature';
}

class _Api {
  _Api({this.manager = false, this.resident = true});
  final bool manager, resident;
  final List<http.Request> requests = [];
  Completer<void>? pendingWrite;
  final Map<String, Object?> item = {
    'id': 'complaint-1',
    'residencyId': 'residence-1',
    'title': 'Iluminação QA',
    'category': 'areas_comuns',
    'description': 'O corredor de acesso está sem iluminação.',
    'status': 'aberta',
    'createdAt': '2026-11-01T12:00:00Z',
    'updatedAt': '2026-11-01T12:00:00Z',
    'closedAt': null,
    'responses': <Map<String, Object?>>[],
    'history': <Map<String, Object?>>[],
  };
  http.Response json(Object? body, [int status = 200]) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );
  Future<http.Response> handle(http.Request request) async {
    requests.add(request);
    final path = request.url.path;
    if (path == '/auth/login') return json({'token': 'account-token'});
    if (path == '/account') return json(accountUsers);
    if (path == '/auth') {
      return json({'token': _token(manager: manager, resident: resident)});
    }
    if (path == '/posts') return json(posts);
    expect(
      request.headers['Authorization'],
      'Bearer ${_token(manager: manager, resident: resident)}',
    );
    if (request.method == 'GET' &&
        ['/complaints', '/complaints/residency'].contains(path)) {
      return json([
        {
          for (final entry in item.entries)
            if (!['responses', 'history'].contains(entry.key))
              entry.key: entry.value,
        },
      ]);
    }
    if (request.method == 'GET' && path == '/complaints/complaint-1') {
      return json(item);
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    if (request.method == 'POST' && path == '/complaints') {
      if (pendingWrite != null) await pendingWrite!.future;
      expect(body.keys.toSet(), {'title', 'category', 'description'});
      item.addAll(body);
      return json(item, 201);
    }
    if (path.endsWith('/responses')) {
      expect(body.keys.toSet(), {'message'});
      (item['responses'] as List).add({
        'id': 'response-1',
        'authorUserId': 'internal-identity',
        'isAdministrative': true,
        'message': body['message'],
        'createdAt': '2026-11-01T12:10:00Z',
      });
      return json(item, 201);
    }
    if (path.endsWith('/status')) {
      item['status'] = body['status'];
      return json(item);
    }
    return json({}, 404);
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _menu(WidgetTester tester, String destination) async {
  await _tap(tester, find.byKey(ValueKey('menu-$destination')));
}

Future<void> _launch(
  WidgetTester tester,
  _Api api, {
  String language = 'pt',
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final client = MockClient(api.handle);
  addTearDown(client.close);
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  await tester.runAsync(() async {
    await tester.pumpWidget(
      RepaintBoundary(
        key: _boundary,
        child: HiveApp(
          client: client,
          sessionStorage: FakeSessionStorage(),
          userDataStorage: FakeUserDataStorage(),
          preferencesStorage: FakePreferencesStorage(),
          locale: Locale(language),
        ),
      ),
    );
    await tester.pump();
  });
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'qa@example.test');
  await tester.enterText(find.byType(TextFormField).at(1), 'synthetic-only');
  await _tap(tester, find.byKey(const Key('login-submit')));
  await _tap(tester, find.byKey(const ValueKey('building-user-1')));
  expect(find.byType(HomeScreen), findsOneWidget);
  await _menu(tester, '/complaints');
  expect(find.byType(ComplaintsScreen), findsOneWidget);
}

Future<void> _captureImage(WidgetTester tester, String name) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('../../k8s/.local/audit/complaints-qa/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await rootBundle.loadString('lib/lang/pt/login.json');
    await rootBundle.loadString('lib/lang/pt/app.json');
    await GlobalMaterialLocalizations.delegate.load(const Locale('pt'));
    await GlobalCupertinoLocalizations.delegate.load(const Locale('pt'));
    if (_capture && Platform.isWindows) {
      final font = FontLoader('Roboto')
        ..addFont(
          File('C:/Windows/Fonts/segoeui.ttf')
              .readAsBytes()
              .then(ByteData.sublistView),
        );
      await font.load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });

  testWidgets(
    'resident opens real route, creates via HTTP adapter, returns to settings and logs out',
    (tester) async {
      final api = _Api();
      await _launch(tester, api);
      expect(
        api.requests.where(
          (request) => request.url.path == '/complaints/residency',
        ),
        isNotEmpty,
      );
      await _captureImage(tester, 'flutter-complaints-route-list');
      await _tap(tester, find.byKey(const ValueKey('new-complaint')));
      await tester.enterText(
        find.byKey(const ValueKey('complaint-subject')),
        'Reclamação pela rota real',
      );
      await tester.enterText(
        find.byKey(const ValueKey('complaint-description')),
        'Relato integrado pelo cliente HTTP.',
      );
      tester.testTextInput.hide();
      await _tap(tester, find.byKey(const ValueKey('complaint-category')));
      await _tap(tester, find.text('Outros').last);
      await _captureImage(tester, 'flutter-complaints-route-create');
      await _tap(tester, find.byKey(const ValueKey('submit-complaint')));
      expect(
        api.requests
            .where(
              (request) =>
                  request.method == 'POST' && request.url.path == '/complaints',
            )
            .length,
        1,
      );
      expect(api.item['title'], 'Reclamação pela rota real');
      expect(find.byKey(const ValueKey('complaint-response')), findsNothing);
      await _menu(tester, '/settings');
      expect(find.byType(SettingsScreen), findsOneWidget);
      await _menu(tester, '/home');
      expect(find.byType(HomeScreen), findsOneWidget);
      await _tap(tester, find.byKey(const Key('menu-sign-out')));
      expect(find.byType(Login), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Back closes the local form then returns Home and reopening reloads',
    (tester) async {
      final api = _Api();
      await _launch(tester, api);
      final state = tester.state(find.byType(ComplaintsScreen));
      final reads = api.requests
          .where((request) => request.url.path == '/complaints/residency')
          .length;
      await _tap(tester, find.byKey(const ValueKey('new-complaint')));
      await tester.enterText(
        find.byKey(const ValueKey('complaint-subject')),
        'Rascunho',
      );
      tester.testTextInput.hide();
      for (final width in [320.0, 768.0, 1024.0, 1440.0]) {
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpAndSettle();
        expect(tester.state(find.byType(ComplaintsScreen)), same(state));
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('complaint-subject')),
              )
              .controller!
              .text,
          'Rascunho',
        );
        expect(tester.takeException(), isNull);
      }
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await _tap(tester, find.widgetWithText(FilledButton, 'Descartar'));
      expect(find.byType(ComplaintsScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('complaint-subject')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      await _menu(tester, '/complaints');
      expect(tester.state(find.byType(ComplaintsScreen)), isNot(same(state)));
      expect(
        api.requests
            .where((request) => request.url.path == '/complaints/residency')
            .length,
        reads + 1,
      );
    },
  );

  testWidgets('submission blocks sidebar, logout and Back until completion', (
    tester,
  ) async {
    final api = _Api()..pendingWrite = Completer<void>();
    await _launch(tester, api);
    await _tap(tester, find.byKey(const ValueKey('new-complaint')));
    await tester.enterText(
      find.byKey(const ValueKey('complaint-subject')),
      'Iluminação do corredor',
    );
    await tester.enterText(
      find.byKey(const ValueKey('complaint-description')),
      'A iluminação do corredor precisa de manutenção.',
    );
    tester.testTextInput.hide();
    await _tap(tester, find.byKey(const ValueKey('complaint-category')));
    await _tap(tester, find.text('Outros').last);
    final submit = find.byKey(const ValueKey('submit-complaint'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump(const Duration(milliseconds: 200));
    for (final key in ['menu-/settings', 'menu-sign-out']) {
      final destination = find.byKey(ValueKey(key));
      await tester.ensureVisible(destination);
      await tester.tap(destination);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ComplaintsScreen), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    }
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('complaint-subject')), findsOneWidget);
    api.pendingWrite!.complete();
    await tester.pumpAndSettle();
    await _menu(tester, '/settings');
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['pt', 'en', 'es']) {
    testWidgets(
      'integrated complaints fits narrow panel at 200% in $language',
      (tester) async {
        await _launch(tester, _Api(manager: true), language: language);
        tester.view.physicalSize = const Size(320, 800);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _tap(
          tester,
          find.byKey(const ValueKey('complaint-toggle-complaint-1')),
        );
        expect(tester.takeException(), isNull);
        await _tap(tester, find.byKey(const ValueKey('new-complaint')));
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.byKey(const ValueKey('submit-complaint')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'core administrator manages through integrated route without complaint grant',
    (tester) async {
      final api = _Api(manager: true, resident: false);
      await _launch(tester, api);
      expect(
        api.requests.where((request) => request.url.path == '/complaints'),
        isNotEmpty,
      );
      expect(find.byKey(const ValueKey('new-complaint')), findsOneWidget);
      await _tap(tester, find.text('Iluminação QA'));
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('close-complaint')))
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('complaint-response')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('complaint-response')),
        'Resposta integrada QA',
      );
      tester.testTextInput.hide();
      await _tap(tester, find.byKey(const ValueKey('send-response')));
      expect(api.item['status'], 'aberta');
      expect(
        api.requests
            .where((request) => request.url.path.endsWith('/responses'))
            .length,
        1,
      );
      await _captureImage(tester, 'flutter-complaints-route-admin');
      // Let the success feedback finish before the next action in the content.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('close-complaint')));
      final dialog = find.byType(AlertDialog);
      await _tap(
        tester,
        find.descendant(
          of: dialog,
          matching: find.widgetWithText(FilledButton, 'Encerrar atendimento'),
        ),
      );
      expect(api.item['status'], 'encerrada');
      expect(find.byKey(const ValueKey('complaint-response')), findsNothing);
      expect(find.textContaining('internal-identity'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'system back and sidebar navigation confirm draft discard and preserve settings',
    (tester) async {
      final api = _Api();
      await _launch(tester, api);
      await _tap(tester, find.text('Iluminação QA'));
      await _tap(
        tester,
        find.byKey(const ValueKey('complaint-toggle-complaint-1')),
      );
      await _tap(tester, find.byKey(const ValueKey('new-complaint')));
      await tester.enterText(
        find.byKey(const ValueKey('complaint-subject')),
        'Rascunho preservado',
      );
      tester.testTextInput.hide();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await _tap(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Cancelar'),
        ),
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('complaint-subject')),
            )
            .controller!
            .text,
        'Rascunho preservado',
      );

      await _menu(tester, '/settings');
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);
      await _tap(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Cancelar'),
        ),
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('complaint-subject')),
            )
            .controller!
            .text,
        'Rascunho preservado',
      );
      await _menu(tester, '/settings');
      await _tap(tester, find.widgetWithText(FilledButton, 'Descartar'));
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('menu-/complaints')), findsOneWidget);
      expect(find.byKey(const ValueKey('menu-/settings')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
