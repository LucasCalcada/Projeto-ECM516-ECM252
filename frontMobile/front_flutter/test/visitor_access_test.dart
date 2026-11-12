import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/helpers/api_client.dart';
import 'package:front_flutter/helpers/visitor_service.dart';
import 'package:front_flutter/helpers/visitor_entry_datetime.dart';
import 'package:front_flutter/lang/app_localizations.dart';
import 'package:front_flutter/routes/app_routes.dart';
import 'package:front_flutter/routes/menu_destination.dart';
import 'package:front_flutter/theme/app_theme.dart';
import 'package:front_flutter/types/api_failure.dart';
import 'package:front_flutter/types/user_session.dart';
import 'package:front_flutter/types/visitor_access.dart';
import 'package:front_flutter/views/visitor_access.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _translations = <String, AppLocalizations>{};

class _TestTranslations extends LocalizationsDelegate<AppLocalizations> {
  const _TestTranslations();
  @override
  bool isSupported(Locale locale) =>
      _translations.containsKey(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(_translations[locale.languageCode]!);
  @override
  bool shouldReload(_TestTranslations old) => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final language in ['pt', 'en', 'es']) {
      await rootBundle.loadString('lib/lang/$language/app.json');
      _translations[language] = await AppLocalizations.delegate.load(
        Locale(language),
      );
      await GlobalMaterialLocalizations.delegate.load(Locale(language));
      await GlobalCupertinoLocalizations.delegate.load(Locale(language));
    }
    if (const bool.fromEnvironment('CAPTURE_PREVIEWS')) {
      if (Platform.isWindows) {
        final font = FontLoader('TestVisitorFont')
          ..addFont(
            File('C:/Windows/Fonts/segoeui.ttf')
                .readAsBytes()
                .then(ByteData.sublistView),
          );
        await font.load();
      }
    }
  });
  test('manual entry accepts valid local dates and 24-hour boundaries', () {
    for (final hour in [0, 12, 23]) {
      final text = '08/11/2026 ${hour.toString().padLeft(2, '0')}:59';
      expect(parseVisitorEntryDateTime(text), DateTime(2026, 11, 8, hour, 59));
    }
    expect(
      parseVisitorEntryDateTime('08/11/2026 00:00'),
      DateTime(2026, 11, 8),
    );
    expect(
      parseVisitorEntryDateTime('29/02/2024 12:00'),
      DateTime(2024, 2, 29, 12),
    );
    expect(
      parseVisitorEntryDateTime('29/02/2000 12:00'),
      DateTime(2000, 2, 29, 12),
    );
    expect(
      parseVisitorEntryDateTime(' 08/11/2040 23:30 '),
      DateTime(2040, 11, 8, 23, 30),
    );
    expect(parseVisitorEntryDateTime('08/11/2026 23:30')!.isUtc, isFalse);
  });

  test('manual entry rejects invalid, normalized and incomplete dates', () {
    for (final value in [
      '',
      '31/02/2026 12:00',
      '29/02/2025 12:00',
      '29/02/1900 12:00',
      '31/04/2026 12:00',
      '00/11/2026 12:00',
      '08/00/2026 12:00',
      '08/13/2026 12:00',
      '08/11/0000 12:00',
      '08/11/2026 24:00',
      '08/11/2026 23:60',
      '08/11/2026 11:30 PM',
      '08/11/2026',
      '08/11/2026 2:30',
      '08/11/2026 23:',
      '2026-11-08T23:30',
    ]) {
      expect(parseVisitorEntryDateTime(value), isNull, reason: value);
    }
  });

  for (final locale in ['pt', 'en', 'es']) {
    for (final width in [320.0, 1200.0]) {
      testWidgets('manual entry validation and editing in $locale at $width', (
        tester,
      ) async {
        final requests = <http.Request>[];
        await _mount(
          tester,
          session: _session(permissions: ['@visitor:create']),
          requests: requests,
          locale: Locale(locale),
          size: Size(width, 1000),
        );
        final entry = find.byKey(const Key('visitor-entry'));
        await tester.ensureVisible(entry);
        await tester.tap(entry);
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsNothing);
        expect(find.byType(TimePickerDialog), findsNothing);
        await tester.enterText(find.byKey(const Key('visitor-name')), 'Ana');
        await tester.enterText(find.byKey(const Key('visitor-cpf')), '123');
        await tester.enterText(find.byKey(const Key('visitor-rg')), '456');
        for (final invalid in [
          '31/02/2026 12:00',
          '08/11/2026 24:00',
          '08/11/2026 23:60',
          '08/11/2026 11:30 PM',
          '08/11/2026',
        ]) {
          await tester.enterText(entry, invalid);
          await tester.ensureVisible(find.byKey(const Key('visitor-submit')));
          await tester.tap(find.byKey(const Key('visitor-submit')));
          await tester.pumpAndSettle();
          expect(requests, isEmpty);
          expect(
            tester
                .widget<EditableText>(
                  find.descendant(
                    of: entry,
                    matching: find.byType(EditableText),
                  ),
                )
                .focusNode
                .hasFocus,
            isTrue,
          );
          final state = tester.state<FormFieldState<String>>(entry);
          expect(state.errorText, isNotEmpty);
          expect(tester.takeException(), isNull);
          if (invalid == '31/02/2026 12:00' && locale == 'pt') {
            await _preview(tester, 'visitor-error-$width');
          }
        }
        // Text input replacement exercises the same editing path as pasted text.
        await tester.enterText(entry, '08/11/2026 23:30');
        await tester.pumpAndSettle();
        if (locale == 'pt') await _preview(tester, 'visitor-manual-$width');
        await tester.enterText(entry, '');
        await tester.ensureVisible(find.byKey(const Key('visitor-submit')));
        await tester.tap(find.byKey(const Key('visitor-submit')));
        await tester.pumpAndSettle();
        expect(
          jsonDecode(requests.single.body).containsKey('entryAt'),
          isFalse,
        );
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 5));
      });
    }
  }

  testWidgets('history uses HH:mm even in English on a 12-hour device', (
    tester,
  ) async {
    final local = DateTime(2026, 11, 8, 23, 5);
    await _mount(
      tester,
      session: _session(permissions: ['@visitor:view']),
      locale: const Locale('en'),
      onRequest: (_) async => http.Response(
        jsonEncode([
          {
            'id': 'access-1',
            'buildingId': 'building-1',
            'residencyId': 'res-1',
            'name': 'Ana',
            'cpf': '123',
            'rg': '456',
            'entryAt': local.toUtc().toIso8601String(),
          },
        ]),
        200,
      ),
    );
    expect(find.textContaining('23:05'), findsOneWidget);
    expect(find.textContaining('PM'), findsNothing);
  });

  test('residency label prefers code, then name, then id', () {
    final json = {
      'id': 'access-1',
      'buildingId': 'building-1',
      'residencyId': 'res-1',
      'rg': '00.000.000-0',
      'cpf': '123.456.789-00',
      'name': 'Ana Costa',
      'entryAt': '2026-11-05T18:30:00.000Z',
    };
    expect(
      VisitorAccess.fromJson({
        ...json,
        'residencyCode': 'B-12',
        'residencyName': 'Bloco B',
      }).residencyLabel,
      'B-12',
    );
    expect(
      VisitorAccess.fromJson({...json, 'residencyName': 'Bloco B'})
          .residencyLabel,
      'Bloco B',
    );
    expect(VisitorAccess.fromJson(json).residencyLabel, 'res-1');
    expect(
      VisitorAccess.fromJson({...json, 'entryAt': '2026-11-05T18:30:00.000Z'})
          .entryAt
          .isUtc,
      isTrue,
    );
  });

  test('list and register use the user token and visitor routes', () async {
    final requests = <http.Request>[];
    final service = _service((request) async {
      requests.add(request);
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode([
            {
              'id': 'access-1',
              'buildingId': 'building-1',
              'residencyId': 'res-1',
              'residencyCode': 'B-12',
              'rg': '00.000.000-0',
              'cpf': '123.456.789-00',
              'name': 'Ana Costa',
              'entryAt': '2026-11-05T18:30:00.000Z',
            },
          ]),
          200,
        );
      }
      return http.Response('{}', 200);
    });
    final current = _session(permissions: ['@visitor:view']);
    final listed = await service.list(current);
    expect(listed.single.name, 'Ana Costa');
    expect(listed.single.residencyLabel, 'B-12');

    final entry = DateTime.utc(2026, 11, 5, 15, 30);
    await service.register(
      current,
      name: 'Ana Costa',
      cpf: '123.456.789-00',
      rg: '00.000.000-0',
      entryAt: entry,
    );
    await service.register(
      current,
      name: 'Sem horário',
      cpf: '123.456.789-00',
      rg: '00.000.000-0',
    );

    expect(requests.map((request) => request.method), ['GET', 'POST', 'POST']);
    expect(requests.map((request) => request.url.path), [
      '/access',
      '/access/register',
      '/access/register',
    ]);
    expect(
      requests.every(
        (request) => request.headers['Authorization'] == 'Bearer user-token',
      ),
      isTrue,
    );
    final withEntry = jsonDecode(requests[1].body) as Map<String, dynamic>;
    expect(withEntry['entryAt'], entry.toIso8601String());
    expect(withEntry['name'], 'Ana Costa');
    final withoutEntry = jsonDecode(requests[2].body) as Map<String, dynamic>;
    expect(withoutEntry.containsKey('entryAt'), isFalse);

    final invalid = _service(
      (_) async => http.Response(jsonEncode({'ok': true}), 200),
    );
    await expectLater(
      invalid.list(current),
      throwsA(
        isA<ApiException>().having(
          (error) => error.failure,
          'failure',
          ApiFailure.invalidResponse,
        ),
      ),
    );

    var called = false;
    final expiredService = _service((_) async {
      called = true;
      return http.Response('[]', 200);
    });
    await expectLater(
      expiredService.list(
        _session(
          permissions: ['@visitor:view'],
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.failure,
          'failure',
          ApiFailure.unauthorized,
        ),
      ),
    );
    expect(called, isFalse);
  });

  test('visitor access menu uses the react permission strings', () {
    final entry = MenuDestination.entries.singleWhere(
      (item) => item.route == AppRoutes.visitorAccess,
    );
    expect(entry.available, isTrue);
    expect(entry.permissions, ['@visitor:view', '@visitor:create']);
    expect(entry.canOpen(_session(permissions: ['@visitor:create'])), isTrue);
    expect(
      entry.canOpen(
        _session(permissions: ['@visitor:view'], residencyId: null),
      ),
      isTrue,
    );
    expect(entry.canOpen(_session(permissions: ['@core:admin'])), isTrue);
    expect(
      entry.canOpen(_session(permissions: ['@complaint:create'])),
      isFalse,
    );
  });

  testWidgets('create with residency shows only the form', (tester) async {
    final requests = <http.Request>[];
    await _mount(
      tester,
      session: _session(permissions: ['@visitor:create']),
      requests: requests,
    );
    expect(find.text('Registrar visita'), findsOneWidget);
    expect(find.byKey(const Key('visitor-name')), findsOneWidget);
    expect(find.byKey(const Key('visitor-mode-view')), findsNothing);
    expect(requests, isEmpty);
  });

  testWidgets('create without residency is denied', (tester) async {
    await _mount(
      tester,
      session: _session(permissions: ['@visitor:create'], residencyId: null),
    );
    expect(find.text('Acesso negado'), findsOneWidget);
    expect(find.byKey(const Key('visitor-name')), findsNothing);
  });

  testWidgets('view shows the history and not an empty failure', (
    tester,
  ) async {
    var calls = 0;
    await _mount(
      tester,
      session: _session(permissions: ['@visitor:view'], residencyId: null),
      onRequest: (request) async {
        calls++;
        expect(request.method, 'GET');
        expect(request.url.path, '/access');
        if (calls == 1) return http.Response('unavailable', 500);
        return _accessResponse();
      },
    );
    expect(find.text('Histórico de visitas'), findsOneWidget);
    expect(find.byKey(const Key('visitor-mode-create')), findsNothing);
    expect(find.text('Não foi possível listar os acessos.'), findsOneWidget);
    expect(find.text('Nenhum acesso encontrado.'), findsNothing);
    expect(find.text('Ana Costa'), findsNothing);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Ana Costa'), findsOneWidget);
    expect(find.text('B-12'), findsOneWidget);
    expect(find.text('Não foi possível listar os acessos.'), findsNothing);
  });

  testWidgets('both modes start on register and can open history', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await _mount(
      tester,
      session: _session(permissions: ['@visitor:create', '@visitor:view']),
      requests: requests,
      onRequest: (_) async => _accessResponse(),
    );
    expect(find.text('Registrar visita'), findsOneWidget);
    expect(find.byKey(const Key('visitor-mode-create')), findsOneWidget);
    expect(find.byKey(const Key('visitor-mode-view')), findsOneWidget);
    expect(requests, isEmpty);

    await tester.tap(find.byKey(const Key('visitor-mode-view')));
    await tester.pumpAndSettle();
    expect(find.text('Histórico de visitas'), findsOneWidget);
    expect(requests.single.url.path, '/access');
  });

  testWidgets('core admin follows create and view rules', (tester) async {
    await _mount(
      tester,
      session: _session(permissions: ['@core:admin']),
      onRequest: (_) async => _accessResponse(),
    );
    expect(find.byKey(const Key('visitor-mode-create')), findsOneWidget);
    expect(find.byKey(const Key('visitor-mode-view')), findsOneWidget);

    await _mount(
      tester,
      session: _session(permissions: ['@core:admin'], residencyId: null),
      onRequest: (_) async => _accessResponse(),
    );
    expect(find.text('Histórico de visitas'), findsOneWidget);
    expect(find.byKey(const Key('visitor-mode-create')), findsNothing);
  });

  testWidgets('empty permissions show access denied', (tester) async {
    final requests = <http.Request>[];
    await _mount(tester, session: _session(), requests: requests);
    expect(find.text('Acesso negado'), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('submit validates fields, keeps the draft and then registers', (
    tester,
  ) async {
    final requests = <http.Request>[];
    Completer<http.Response>? pending;
    await _mount(
      tester,
      session: _session(permissions: ['@visitor:create']),
      onRequest: (request) {
        requests.add(request);
        final next = Completer<http.Response>();
        pending = next;
        return next.future;
      },
    );

    await tester.tap(find.byKey(const Key('visitor-submit')));
    await tester.pump();
    expect(find.text('Informe o nome.'), findsOneWidget);
    expect(find.text('Informe o CPF.'), findsOneWidget);
    expect(find.text('Informe o RG.'), findsOneWidget);
    expect(requests, isEmpty);

    await tester.enterText(find.byKey(const Key('visitor-name')), 'Ana Costa');
    await tester.enterText(
      find.byKey(const Key('visitor-cpf')),
      '123.456.789-00',
    );
    await tester.enterText(find.byKey(const Key('visitor-rg')), '00.000.000-0');
    await tester.enterText(
      find.byKey(const Key('visitor-entry')),
      '08/11/2026 23:30',
    );
    await tester.tap(find.byKey(const Key('visitor-submit')));
    await tester.pump();
    expect(find.text('Registrando...'), findsOneWidget);

    pending!.complete(http.Response('no', 500));
    await tester.pump();
    expect(find.text('Não foi possível registrar o acesso.'), findsOneWidget);
    expect(find.text('Ana Costa'), findsOneWidget);
    expect(find.text('08/11/2026 23:30'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('visitor-submit')));
    await tester.pump();
    final body = jsonDecode(requests.last.body) as Map<String, dynamic>;
    expect(requests.last.method, 'POST');
    expect(requests.last.url.path, '/access/register');
    expect(requests.last.headers['Authorization'], 'Bearer user-token');
    expect(body['name'], 'Ana Costa');
    expect(body['cpf'], '123.456.789-00');
    expect(body['rg'], '00.000.000-0');
    expect(
      body['entryAt'],
      DateTime(2026, 11, 8, 23, 30).toUtc().toIso8601String(),
    );

    pending!.complete(http.Response('{}', 200));
    await tester.pumpAndSettle();
    expect(find.text('Entrada registrada com sucesso.'), findsOneWidget);
    expect(find.text('Ana Costa'), findsNothing);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('visitor-entry')))
          .controller!
          .text,
      isEmpty,
    );
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('expired session during submit leaves the screen', (
    tester,
  ) async {
    final requests = <http.Request>[];
    Completer<http.Response>? pending;
    var expired = false;
    await _mount(
      tester,
      session: _session(permissions: ['@visitor:create']),
      onRequest: (request) {
        requests.add(request);
        final next = Completer<http.Response>();
        pending = next;
        return next.future;
      },
      onSessionExpired: () => expired = true,
    );
    await tester.enterText(find.byKey(const Key('visitor-name')), 'Ana Costa');
    await tester.enterText(
      find.byKey(const Key('visitor-cpf')),
      '123.456.789-00',
    );
    await tester.enterText(find.byKey(const Key('visitor-rg')), '00.000.000-0');
    await tester.tap(find.byKey(const Key('visitor-submit')));
    await tester.pump();
    pending!.complete(http.Response('{}', 401));
    await tester.pump();
    expect(expired, isTrue);
    expect(find.text('Ana Costa'), findsOneWidget);
    expect(requests.single.url.path, '/access/register');
  });
}

VisitorService _service(
  Future<http.Response> Function(http.Request request) handle,
) {
  final client = MockClient(handle);
  addTearDown(client.close);
  return VisitorService(
    ApiClient(client: client, baseUrl: 'https://example.test'),
  );
}

UserSession _session({
  List<String> permissions = const [],
  String? residencyId = 'res-1',
  DateTime? expiresAt,
}) {
  return UserSession(
    token: 'user-token',
    userId: 'user-1',
    buildingId: 'building-1',
    buildingName: 'Condomínio QA',
    residencyId: residencyId,
    permissions: permissions,
    expiresAt: expiresAt ?? DateTime.utc(2100),
  );
}

http.Response _accessResponse() => http.Response(
  jsonEncode([
    {
      'id': 'access-1',
      'buildingId': 'building-1',
      'residencyId': 'res-1',
      'residencyCode': 'B-12',
      'residencyName': 'Bloco B',
      'rg': '00.000.000-0',
      'cpf': '123.456.789-00',
      'name': 'Ana Costa',
      'entryAt': '2026-11-05T18:30:00.000Z',
    },
  ]),
  200,
);

Future<void> _mount(
  WidgetTester tester, {
  required UserSession session,
  List<http.Request>? requests,
  Future<http.Response> Function(http.Request request)? onRequest,
  VoidCallback? onSessionExpired,
  Locale locale = const Locale('pt'),
  Size size = const Size(900, 1000),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final service = _service((request) {
    requests?.add(request);
    if (onRequest != null) return onRequest(request);
    return Future.value(http.Response('[]', 200));
  });
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
      supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
      localizationsDelegates: const [
        _TestTranslations(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: HiveTheme.apply(ThemeData.dark(useMaterial3: true)).copyWith(
        textTheme: const bool.fromEnvironment('CAPTURE_PREVIEWS')
            ? HiveTheme.apply(ThemeData.dark(useMaterial3: true)).textTheme
                  .apply(fontFamily: 'TestVisitorFont')
            : null,
      ),
      home: RepaintBoundary(
        key: const Key('visitor-preview'),
        child: Scaffold(
          body: VisitorAccessView(
            session: session,
            service: service,
            onSessionExpired: onSessionExpired ?? () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('visitor-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
