import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/helpers/api_client.dart';
import 'package:front_flutter/helpers/visitor_service.dart';
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

void main() {
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
      VisitorAccess.fromJson({
        ...json,
        'residencyName': 'Bloco B',
      }).residencyLabel,
      'Bloco B',
    );
    expect(VisitorAccess.fromJson(json).residencyLabel, 'res-1');
    expect(
      VisitorAccess.fromJson({
        ...json,
        'entryAt': '2026-11-05T18:30:00.000Z',
      }).entryAt.isUtc,
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
    expect(
      entry.canOpen(_session(permissions: ['@visitor:create'])),
      isTrue,
    );
    expect(
      entry.canOpen(
        _session(permissions: ['@visitor:view'], residencyId: null),
      ),
      isTrue,
    );
    expect(entry.canOpen(_session(permissions: ['@core:admin'])), isTrue);
    expect(entry.canOpen(_session(permissions: ['@complaint:create'])), isFalse);
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

  testWidgets('view shows the history and not an empty failure', (tester) async {
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
    await tester.tap(find.byKey(const Key('visitor-submit')));
    await tester.pump();
    expect(find.text('Registrando...'), findsOneWidget);

    pending!.complete(http.Response('no', 500));
    await tester.pump();
    expect(find.text('Não foi possível registrar o acesso.'), findsOneWidget);
    expect(find.text('Ana Costa'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));

    await tester.tap(find.byKey(const Key('visitor-submit')));
    await tester.pump();
    final body = jsonDecode(requests.last.body) as Map<String, dynamic>;
    expect(requests.last.method, 'POST');
    expect(requests.last.url.path, '/access/register');
    expect(requests.last.headers['Authorization'], 'Bearer user-token');
    expect(body['name'], 'Ana Costa');
    expect(body['cpf'], '123.456.789-00');
    expect(body['rg'], '00.000.000-0');
    expect(body.containsKey('entryAt'), isFalse);

    pending!.complete(http.Response('{}', 200));
    await tester.pump();
    expect(find.text('Entrada registrada com sucesso.'), findsOneWidget);
    expect(find.text('Ana Costa'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('expired session during submit leaves the screen', (tester) async {
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
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(900, 1000);
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
      locale: const Locale('pt'),
      supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: HiveTheme.apply(ThemeData.dark(useMaterial3: true)),
      home: Scaffold(
        body: VisitorAccessView(
          session: session,
          service: service,
          onSessionExpired: onSessionExpired ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
