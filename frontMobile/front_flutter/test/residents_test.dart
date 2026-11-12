import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/helpers/api_client.dart';
import 'package:front_flutter/helpers/residents_service.dart';
import 'package:front_flutter/lang/app_localizations.dart';
import 'package:front_flutter/types/api_failure.dart';
import 'package:front_flutter/types/user_session.dart';
import 'package:front_flutter/views/residents.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

late AppLocalizations _strings;
class _Translations extends LocalizationsDelegate<AppLocalizations> {
  const _Translations();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'pt';
  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(_strings);
  @override
  bool shouldReload(_Translations old) => false;
}

UserSession session({List<String> permissions = const ['@core:user:manage'], String userId = 'manager'}) => UserSession(
  token: 'token', userId: userId, buildingId: 'b', buildingName: 'Condomínio',
  permissions: permissions, expiresAt: DateTime.utc(2100),
);
http.Response jsonResponse(Object value, [int status = 200]) => http.Response(jsonEncode(value), status, headers: {'content-type': 'application/json; charset=utf-8'});
Map<String, Object> resident([String name = 'Ana']) => {'id': 'u', 'name': name, 'permissions': ['@visitor:create']};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    _strings = await AppLocalizations.delegate.load(const Locale('pt'));
    await GlobalMaterialLocalizations.delegate.load(const Locale('pt'));
    await GlobalCupertinoLocalizations.delegate.load(const Locale('pt'));
  });

  test('residents permission is management or core admin, with no denied request', () async {
    var calls = 0;
    final client = MockClient((_) async { calls++; return jsonResponse({'groups': []}); });
    addTearDown(client.close);
    final service = ResidentsService(ApiClient(client: client, baseUrl: 'https://example.test'));
    await expectLater(service.groups(session(permissions: [])), throwsA(isA<ApiException>().having((e) => e.failure, 'failure', ApiFailure.forbidden)));
    expect(calls, 0);
    await service.groups(session());
    await service.groups(session(permissions: ['@core:admin']));
    expect(calls, 2);
  });

  test('empty lists use 404, updates trim and deduplicate, self sends only name', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'GET') return jsonResponse({}, 404);
      return jsonResponse({'user': resident('Maria')});
    });
    addTearDown(client.close);
    final service = ResidentsService(ApiClient(client: client, baseUrl: 'https://example.test'));
    expect(await service.groups(session()), isEmpty);
    expect(await service.residencies(session(), 'g'), isEmpty);
    expect(await service.residents(session(), 'r'), isEmpty);
    await service.update(session(), 'u', name: ' Maria ', permissions: [' @visitor:create ', '', '@visitor:create']);
    expect(requests.last.method, 'PUT');
    expect(requests.last.headers['Authorization'], 'Bearer token');
    expect(jsonDecode(requests.last.body), {'name': 'Maria', 'permissions': ['@visitor:create']});
    await service.update(session(userId: 'u'), 'u', name: 'Maria', permissions: ['@core:admin']);
    expect(jsonDecode(requests.last.body), {'name': 'Maria'});
    await expectLater(service.detail(session(), 'missing'), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404)));
  });

  testWidgets('tree is lazy; cancelled edit does not change row; saved edit does', (tester) async {
    final requests = <http.Request>[];
    await mount(tester, requests: requests);
    expect(requests.map((r) => r.url.path), ['/groups']);
    await tester.tap(find.byKey(const ValueKey('residents-group-g')));
    await tester.pumpAndSettle();
    expect(requests.last.url.path, '/residencies/list/g');
    await tester.tap(find.byKey(const ValueKey('residents-residency-r')));
    await tester.pumpAndSettle();
    expect(requests.last.url.path, '/residencies/r/users');
    await tester.tap(find.byKey(const ValueKey('resident-edit-u')));
    await tester.pumpAndSettle();
    expect(requests.last.url.path, '/user/u');
    await tester.enterText(find.byKey(const Key('resident-name')), 'Rascunho');
    await tester.tap(find.byKey(const Key('resident-cancel')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Rascunho'), findsNothing);
    expect(requests.where((r) => r.method == 'PUT'), isEmpty);
    await tester.tap(find.byKey(const ValueKey('resident-edit-u')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('resident-name')), 'Maria');
    await tester.tap(find.byKey(const Key('resident-save')));
    await tester.pumpAndSettle();
    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('Ana'), findsNothing);
    expect(requests.last.method, 'PUT');
  });

  testWidgets('unauthorized view makes no requests', (tester) async {
    final requests = <http.Request>[];
    await mount(tester, requests: requests, current: session(permissions: []));
    expect(requests, isEmpty);
    expect(find.text('Você não tem permissão para gerenciar moradores.'), findsOneWidget);
  });

  testWidgets('self editor explains read-only permissions and saves only name', (tester) async {
    final requests = <http.Request>[];
    await mount(tester, requests: requests, current: session(userId: 'u'));
    await tester.tap(find.byKey(const ValueKey('residents-group-g')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('residents-residency-r')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('resident-edit-u')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('resident-permission-input')), findsNothing);
    expect(find.textContaining('Suas próprias permissões'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('resident-name')), 'Maria');
    await tester.tap(find.byKey(const Key('resident-save')));
    await tester.pumpAndSettle();
    expect(jsonDecode(requests.last.body), {'name': 'Maria'});
  });
}

Future<void> mount(WidgetTester tester, {required List<http.Request> requests, UserSession? current}) async {
  final client = MockClient((request) async {
    requests.add(request);
    if (request.method == 'PUT') return jsonResponse({'user': resident('Maria')});
    return switch (request.url.path) {
      '/groups' => jsonResponse({'groups': [{'id': 'g', 'name': 'Torre A'}]}),
      '/residencies/list/g' => jsonResponse({'residencies': [{'id': 'r', 'name': 'Apartamento 101', 'code': '101'}]}),
      '/residencies/r/users' => jsonResponse({'users': [resident()]}),
      '/user/u' => jsonResponse({'user': resident()}),
      _ => jsonResponse({}, 404),
    };
  });
  addTearDown(client.close);
  addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('pt'),
    supportedLocales: const [Locale('pt')],
    localizationsDelegates: const [_Translations(), GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    home: Scaffold(body: ResidentsView(session: current ?? session(), service: ResidentsService(ApiClient(client: client, baseUrl: 'https://example.test')), onSessionExpired: () {})),
  ));
  await tester.pumpAndSettle();
}
