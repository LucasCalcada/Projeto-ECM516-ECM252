import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/components/packages/package_list.dart';
import 'package:front_flutter/helpers/packages_service.dart';
import 'package:front_flutter/lang/app_localizations.dart';
import 'package:front_flutter/routes/app_routes.dart';
import 'package:front_flutter/routes/menu_destination.dart';
import 'package:front_flutter/theme/app_theme.dart';
import 'package:front_flutter/types/delivery_package.dart';
import 'package:front_flutter/types/user_session.dart';
import 'package:front_flutter/views/packages.dart';
import 'fake_packages_service.dart';

UserSession _session(List<String> permissions, {String? residencyId}) =>
    UserSession(
      token: 'token',
      userId: 'user-1',
      buildingId: 'building-1',
      buildingName: 'Condomínio QA',
      residencyId: residencyId,
      residencyName: residencyId == null ? null : 'Apto 204',
      permissions: permissions,
      expiresAt: DateTime.utc(2100),
    );

/// Serves the real pt strings synchronously so tests stay on the fake clock.
class _TestStringsDelegate extends LocalizationsDelegate<AppLocalizations> {
  _TestStringsDelegate()
    : _strings = AppLocalizations(
        jsonDecode(File('lib/lang/pt/app.json').readAsStringSync())
            as Map<String, dynamic>,
      );

  final AppLocalizations _strings;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(_strings);

  @override
  bool shouldReload(_TestStringsDelegate old) => false;
}

Widget _host(UserSession session, PackagesService service) => MaterialApp(
  locale: const Locale('pt'),
  supportedLocales: const [Locale('pt')],
  localizationsDelegates: [
    _TestStringsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  theme: HiveTheme.apply(ThemeData.dark(useMaterial3: true)),
  home: Scaffold(
    body: PackagesView(
      session: session,
      service: service,
      onSessionExpired: () {},
    ),
  ),
);

class _CountingService extends InMemoryPackagesService {
  _CountingService({super.latency});

  int created = 0;

  @override
  Future<DeliveryPackage> createPackage(
    UserSession session, {
    required String residencyId,
    required String description,
  }) {
    created++;
    return super.createPackage(
      session,
      residencyId: residencyId,
      description: description,
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  UserSession session, [
  PackagesService? service,
]) async {
  await tester.pumpWidget(
    _host(session, service ?? InMemoryPackagesService(latency: Duration.zero)),
  );
  await tester.pumpAndSettle();
}

void main() {
  const modeKey = ValueKey('packages-mode-create');

  group('conditional rendering by permission', () {
    testWidgets('create only: form without mode selector or list', (
      tester,
    ) async {
      await _pump(tester, _session(['@delivery:create']));

      expect(find.byKey(const Key('packages-submit')), findsOneWidget);
      expect(find.byKey(modeKey), findsNothing);
      expect(find.byType(PackageList), findsNothing);
    });

    testWidgets('view:building lists with residency and no confirm button', (
      tester,
    ) async {
      await _pump(tester, _session(['@delivery:view:building']));

      expect(find.byType(PackageList), findsOneWidget);
      expect(find.byKey(const ValueKey('package-pkg-1')), findsOneWidget);
      expect(find.text('Residência'), findsWidgets);
      expect(find.byKey(const ValueKey('package-confirm-pkg-1')), findsNothing);
      expect(find.byKey(const Key('packages-submit')), findsNothing);
    });

    testWidgets('view:residency confirms only pending packages', (
      tester,
    ) async {
      final service = InMemoryPackagesService(latency: Duration.zero);
      await _pump(
        tester,
        _session(['@delivery:view:residency'], residencyId: 'res-1'),
        service,
      );

      FilledButton button(String id) =>
          tester.widget<FilledButton>(find.byKey(ValueKey('package-confirm-$id')));
      expect(button('pkg-1').onPressed, isNotNull); // pending
      expect(button('pkg-2').onPressed, isNull); // already delivered
      // Packages from other residencies are not part of this scope.
      expect(find.byKey(const ValueKey('package-pkg-3')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('package-confirm-pkg-1')));
      await tester.pumpAndSettle();

      expect(button('pkg-1').onPressed, isNull);
      expect(find.text('A encomenda foi marcada como entregue.'), findsOneWidget);
    });

    testWidgets('view:residency without residencyId shows access denied', (
      tester,
    ) async {
      await _pump(tester, _session(['@delivery:view:residency']));

      expect(find.text('Acesso negado'), findsOneWidget);
      expect(find.byType(PackageList), findsNothing);
    });

    testWidgets('no delivery permission shows access denied', (tester) async {
      await _pump(tester, _session(['@reservation:create']));

      expect(find.text('Acesso negado'), findsOneWidget);
    });

    testWidgets('@core:admin gets every mode and can switch', (tester) async {
      await _pump(tester, _session(['@core:admin'], residencyId: 'res-1'));

      expect(find.byKey(modeKey), findsOneWidget);
      expect(
        find.byKey(const ValueKey('packages-mode-building')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('packages-mode-residency')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('packages-submit')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('packages-mode-building')));
      await tester.pumpAndSettle();

      expect(find.byType(PackageList), findsOneWidget);
      expect(find.byKey(const Key('packages-submit')), findsNothing);
    });
  });

  group('create form', () {
    testWidgets('requires a description and keeps nothing created', (
      tester,
    ) async {
      final service = _CountingService(latency: Duration.zero);
      await _pump(tester, _session(['@delivery:create']), service);

      await tester.tap(find.byKey(const Key('packages-submit')));
      await tester.pumpAndSettle();

      expect(
        find.text('Selecione uma residência e informe a descrição.'),
        findsOneWidget,
      );
      expect(service.created, 0);
    });

    testWidgets('registers, confirms after the service and clears the draft', (
      tester,
    ) async {
      final service = _CountingService(latency: Duration.zero);
      final session = _session(['@delivery:create']);
      await _pump(tester, session, service);

      await tester.enterText(
        find.byKey(const ValueKey('packages-description')),
        'Caixa de ferramentas',
      );
      await tester.tap(find.byKey(const Key('packages-submit')));
      await tester.pumpAndSettle();

      expect(service.created, 1);
      expect(find.text('O pacote foi registrado com sucesso.'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('packages-description')),
            )
            .controller!
            .text,
        isEmpty,
      );
      // Service delays use the fake clock, so advance it to let the read finish.
      final read = service.listPackages(session, PackageScope.building);
      await tester.pump(const Duration(milliseconds: 1));
      final stored = await read;
      expect(stored.any((p) => p.description == 'Caixa de ferramentas'), isTrue);
    });

    testWidgets('blocks duplicate submission while pending', (tester) async {
      final service = _CountingService(
        latency: const Duration(milliseconds: 200),
      );
      await _pump(tester, _session(['@delivery:create']), service);

      await tester.enterText(
        find.byKey(const ValueKey('packages-description')),
        'Pacote',
      );
      await tester.tap(find.byKey(const Key('packages-submit')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('packages-submit')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(service.created, 1);
    });
  });

  group('menu', () {
    MenuDestination packages() => MenuDestination.entries.firstWhere(
      (entry) => entry.route == AppRoutes.packages,
    );

    test('opens with any delivery permission or @core:admin', () {
      expect(packages().canOpen(_session(['@delivery:create'])), isTrue);
      expect(packages().canOpen(_session(['@delivery:view:building'])), isTrue);
      expect(packages().canOpen(_session(['@delivery:view:residency'])), isTrue);
      expect(packages().canOpen(_session(['@core:admin'])), isTrue);
    });

    test('stays closed without delivery permissions', () {
      expect(packages().canOpen(_session(['@reservation:create'])), isFalse);
    });
  });
}
