import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/app.dart';
import 'package:front_flutter/helpers/api_client.dart';
import 'package:front_flutter/helpers/communication_service.dart';
import 'package:front_flutter/helpers/core_service.dart';
import 'package:front_flutter/types/api_failure.dart';
import 'package:front_flutter/types/communication_post.dart';
import 'package:front_flutter/types/user_session.dart';
import 'package:front_flutter/routes/app_routes.dart';
import 'package:front_flutter/views/home.dart';
import 'package:front_flutter/views/notifications.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fakes.dart';

const managePermission = '@communication:post:manage';

const buildingDetails = {
  'residentData': [
    {
      'id': 'tower-b',
      'name': 'Torre B',
      'residencies': [
        {'id': 'ap-201', 'name': 'Apartamento 201B'},
      ],
    },
    {
      'id': 'tower-a',
      'name': 'Torre A',
      'residencies': [
        {'id': 'ap-102', 'name': 'Apartamento 102A'},
        {'id': 'ap-101', 'name': 'Apartamento 101A'},
        {'id': 'unnamed', 'name': null},
      ],
    },
  ],
  'remainingUsers': [],
};

const buildingPosts = [
  {
    'id': 'building-post',
    'title': 'Assembleia geral',
    'description': 'Todos convidados.',
    'residencyIds': <String>[],
    'eventAt': null,
    'createdAt': '2026-10-20T12:00:00Z',
  },
  {
    'id': 'residency-post',
    'title': 'Obra no apartamento',
    'description': 'Barulho das 9h às 12h.',
    'residencyIds': ['ap-101', 'ap-102'],
    'eventAt': null,
    'createdAt': '2026-10-19T12:00:00Z',
  },
];

http.Response jsonResponse(Object? value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

ApiClient api(Future<http.Response> Function(http.Request) handler) {
  final client = MockClient(handler);
  addTearDown(client.close);
  return ApiClient(client: client, baseUrl: 'https://example.test');
}

Matcher failsWith(ApiFailure failure) => throwsA(
  isA<ApiException>().having((error) => error.failure, 'failure', failure),
);

Future<void> openNotifications(
  WidgetTester tester, {
  required List<String> permissions,
  required List<http.Request> requests,
}) async {
  final client = MockClient((request) async {
    requests.add(request);
    switch ((request.method, request.url.path)) {
      case ('POST', '/auth/login'):
        return jsonResponse({'token': 'account-token'});
      case ('GET', '/account'):
        return jsonResponse(accountUsers);
      case ('GET', '/auth'):
        return jsonResponse({'token': userToken(permissions: permissions)});
      case ('GET', '/posts'):
        return jsonResponse([buildingPosts.first]);
      case ('GET', '/building/building-1/details'):
        return jsonResponse(buildingDetails);
      case ('POST', '/posts'):
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return jsonResponse({
          ...body,
          'id': 'created',
          'createdAt': '2026-11-01T12:00:00Z',
        });
      default:
        return jsonResponse({}, 404);
    }
  });
  addTearDown(client.close);
  addTearDown(() async => tester.pumpWidget(const SizedBox()));
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      HiveApp(
        client: client,
        sessionStorage: FakeSessionStorage(),
        preferencesStorage: FakePreferencesStorage(),
        locale: const Locale('pt'),
      ),
    );
    await tester.pump();
  });
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'user@example.test');
  await tester.enterText(find.byType(TextFormField).at(1), 'password');
  await tester.ensureVisible(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('building-user-1')));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  if (find.byKey(const ValueKey('menu-/notifications')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const ValueKey('menu-/notifications')));
    await tester.pumpAndSettle();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final language in ['pt', 'en', 'es']) {
      await rootBundle.loadString('lib/lang/$language/login.json');
      await rootBundle.loadString('lib/lang/$language/app.json');
      await GlobalMaterialLocalizations.delegate.load(Locale(language));
    }
  });

  group('communication service', () {
    final session = UserSession.fromToken(userToken());

    test('posts expose their residencies and default to the building', () {
      final targeted = CommunicationPost.fromJson(buildingPosts.last);
      expect(targeted.residencyIds, ['ap-101', 'ap-102']);
      expect(targeted.isBuildingWide, isFalse);
      // Responses without the field keep working (older service versions).
      expect(CommunicationPost.fromJson(posts.first).isBuildingWide, isTrue);
      expect(
        () => CommunicationPost.fromJson({
          ...buildingPosts.first,
          'residencyIds': [1],
        }),
        throwsFormatException,
      );
    });

    test('create sends residencyIds, title and UTC event date', () async {
      late http.Request sent;
      final service = CommunicationService(
        api((request) async {
          sent = request;
          return jsonResponse({
            ...jsonDecode(request.body) as Map<String, dynamic>,
            'id': 'new',
            'createdAt': '2026-11-01T12:00:00Z',
          });
        }),
      );
      final eventAt = DateTime.utc(2026, 12, 1, 18);
      final post = await service.createPost(
        session,
        title: 'Festa',
        description: 'Salão',
        eventAt: eventAt,
        residencyIds: ['ap-101'],
      );
      expect(sent.method, 'POST');
      expect(sent.url.path, '/posts');
      expect(sent.headers['Authorization'], 'Bearer ${session.token}');
      expect(jsonDecode(sent.body), {
        'title': 'Festa',
        'description': 'Salão',
        'eventAt': '2026-12-01T18:00:00.000Z',
        'residencyIds': ['ap-101'],
      });
      expect(post.residencyIds, ['ap-101']);
    });

    test('missing permission is reported as an authorization failure', () {
      final service = CommunicationService(
        api((_) async => http.Response('', 401)),
      );
      expect(
        service.createPost(session, title: 'x', description: 'y'),
        failsWith(ApiFailure.unauthorized),
      );
    });

    test('residencies are grouped, sorted and skip unnamed entries', () async {
      final core = CoreService(
        api((request) async {
          expect(request.url.path, '/building/building-1/details');
          return jsonResponse(buildingDetails);
        }),
      );
      final groups = await core.listResidencies(session);
      expect(groups.map((group) => group.name), ['Torre A', 'Torre B']);
      expect(groups.first.residencies.map((residency) => residency.name), [
        'Apartamento 101A',
        'Apartamento 102A',
      ]);
    });
  });

  testWidgets('residents do not see or open the notifications screen', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await openNotifications(
      tester,
      permissions: ['@reservation:create'],
      requests: requests,
    );

    // The entry is hidden instead of shown locked.
    expect(find.byKey(const ValueKey('menu-/notifications')), findsNothing);
    expect(find.byKey(const ValueKey('menu-/residents')), findsOneWidget);
    expect(find.byType(NotificationsScreen), findsNothing);
    // Routing directly is also redirected to Home.
    await tester.tapAt(const Offset(380, 400));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(HomeScreen)))
        .pushNamed(AppRoutes.notifications);
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsNothing);
  });

  testWidgets('admins create notifications for specific residencies', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await openNotifications(
      tester,
      permissions: [managePermission],
      requests: requests,
    );

    expect(find.byType(NotificationsScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('submit-notification')));
    await tester.pumpAndSettle();
    expect(find.text('Informe o título e a descrição.'), findsNWidgets(2));

    await tester.enterText(
      find.byKey(const Key('notification-title')),
      'Obra no apartamento',
    );
    await tester.enterText(
      find.byKey(const Key('notification-description')),
      'Barulho das 9h às 12h.',
    );
    await tester.tap(find.text('Residências específicas'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('submit-notification')));
    await tester.tap(find.byKey(const Key('submit-notification')));
    await tester.pumpAndSettle();
    expect(find.text('Selecione ao menos uma residência.'), findsOneWidget);
    expect(
      requests.where(
        (request) => request.method == 'POST' && request.url.path == '/posts',
      ),
      isEmpty,
    );

    await tester.tap(find.byKey(const ValueKey('toggle-group-tower-a')));
    await tester.pumpAndSettle();
    expect(find.text('2 selecionada(s)'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('submit-notification')));
    await tester.tap(find.byKey(const Key('submit-notification')));
    await tester.pumpAndSettle();

    final created = requests.lastWhere(
      (request) => request.method == 'POST' && request.url.path == '/posts',
    );
    final body = jsonDecode(created.body) as Map<String, dynamic>;
    expect(body['title'], 'Obra no apartamento');
    expect((body['residencyIds'] as List).toSet(), {'ap-101', 'ap-102'});
    expect(body['eventAt'], isNull);
    expect(find.text('Notificação enviada.'), findsOneWidget);
  });
}
