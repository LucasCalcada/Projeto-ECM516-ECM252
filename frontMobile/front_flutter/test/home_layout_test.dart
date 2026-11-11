import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/helpers/api_client.dart';
import 'package:front_flutter/helpers/communication_service.dart';
import 'package:front_flutter/components/home/event_date_badge.dart';
import 'package:front_flutter/lang/app_localizations.dart';
import 'package:front_flutter/theme/app_theme.dart';
import 'package:front_flutter/types/user_session.dart';
import 'package:front_flutter/views/home.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const capture = bool.fromEnvironment('CAPTURE_PREVIEWS');
final translations = <String, AppLocalizations>{};

class TestTranslations extends LocalizationsDelegate<AppLocalizations> {
  const TestTranslations();
  @override
  bool isSupported(Locale locale) =>
      translations.containsKey(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(translations[locale.languageCode]!);
  @override
  bool shouldReload(TestTranslations old) => false;
}

Map<String, Object?> post(String id, {bool event = false}) => {
  'id': id,
  'title': event
      ? 'Encontro dos moradores $id'
      : 'Aviso importante sobre a manutenção das áreas comuns $id',
  'description':
      'Descrição completa do item $id. A equipe estará disponível para orientar os moradores durante a manutenção.',
  'createdAt': '2026-11-08T12:00:00Z',
  'eventAt': event ? '2026-11-16T22:00:00Z' : null,
};
http.Response response(List<Object?> posts) => http.Response(
  jsonEncode(posts),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Finder toggle(String id) => find.byKey(ValueKey('announcement-toggle-$id'));
Finder details(String id) => find.byKey(ValueKey('announcement-details-$id'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final language in ['pt', 'en', 'es']) {
      translations[language] = await AppLocalizations.delegate.load(
        Locale(language),
      );
      await GlobalMaterialLocalizations.delegate.load(Locale(language));
      await GlobalCupertinoLocalizations.delegate.load(Locale(language));
    }
    if (capture && Platform.isWindows) {
      await (FontLoader('HomePreview')..addFont(
            File('C:/Windows/Fonts/segoeui.ttf')
                .readAsBytes()
                .then(ByteData.sublistView),
          ))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });

  testWidgets(
    'desktop columns align and scroll independently with fixed headings',
    (tester) async {
      await mount(
        tester,
        posts: [
          for (var i = 0; i < 20; i++) post('a$i'),
          for (var i = 0; i < 20; i++) post('e$i', event: true),
        ],
      );
      final left = find.byKey(
        const PageStorageKey('home-announcements-scroll'),
      );
      final right = find.byKey(const PageStorageKey('home-events-scroll'));
      expect(tester.getSize(left).width, tester.getSize(right).width);
      final leftPanel = find.byKey(const ValueKey('home-announcements-panel'));
      final rightPanel = find.byKey(const ValueKey('home-events-panel'));
      expect(tester.getTopLeft(rightPanel).dx - tester.getTopRight(leftPanel).dx, 24);
      expect(tester.getTopLeft(left).dy, tester.getTopLeft(right).dy);
      final heading = find.byKey(const ValueKey('home-announcements-heading'));
      final original = tester.getTopLeft(heading);
      final leftController = tester.widget<CustomScrollView>(left).controller!;
      final rightController = tester
          .widget<CustomScrollView>(right)
          .controller!;
      await tester.drag(left, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(leftController.offset, greaterThan(0));
      expect(rightController.offset, 0);
      expect(tester.getTopLeft(heading), original);
      await tester.drag(right, const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(rightController.offset, greaterThan(0));
    },
  );

  testWidgets(
    'announcements expand independently, with keyboard and semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await mount(tester, posts: [post('a'), post('b')]);
      expect(details('a'), findsNothing);
      expect(find.text('Ler mais'), findsNothing);
      await tester.tap(toggle('a'));
      await tester.pumpAndSettle();
      expect(details('a'), findsOneWidget);
      expect(
        tester
            .getSemantics(toggle('a'))
            .getSemanticsData()
            .flagsCollection
            .isExpanded,
        ui.Tristate.isTrue,
      );
      await tester.tap(toggle('b'));
      await tester.pumpAndSettle();
      expect(details('a'), findsOneWidget);
      expect(details('b'), findsOneWidget);
      final title = find.descendant(
        of: toggle('a'),
        matching: find.byType(Text),
      );
      Focus.of(tester.element(title)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(details('a'), findsNothing);
      expect(details('b'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('calendar keeps date and time visible and expands only its description', (tester) async {
    final semantics = tester.ensureSemantics();
    await mount(tester, posts: [post('a'), post('event', event: true)]);
    final eventToggle = find.byKey(const ValueKey('event-toggle-event'));
    final eventDetails = find.byKey(const ValueKey('event-details-event'));
    expect(eventToggle, findsOneWidget);
    expect(find.byType(EventDateBadge), findsOneWidget);
    expect(find.byKey(const ValueKey('event-time-event')), findsOneWidget);
    expect(eventDetails, findsNothing);
    expect(find.text('Ler mais'), findsNothing);
    expect(find.text('Mostrar menos'), findsNothing);
    await tester.tap(eventToggle);
    await tester.pumpAndSettle();
    expect(eventDetails, findsOneWidget);
    expect(
      tester.getSemantics(eventToggle).getSemanticsData().flagsCollection.isExpanded,
      ui.Tristate.isTrue,
    );
    await tester.tap(toggle('a'));
    await tester.pumpAndSettle();
    expect(details('a'), findsOneWidget);
    expect(eventDetails, findsOneWidget);
    final title = find.descendant(of: eventToggle, matching: find.text('Encontro dos moradores event'));
    Focus.of(tester.element(title)).requestFocus();
    await tester.pumpAndSettle();
    final focusBox = tester.widget<Container>(find.byKey(const ValueKey('home-post-focus-event')));
    expect((focusBox.decoration! as BoxDecoration).border!.top.color, HiveColors.primary);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(eventDetails, findsNothing);
    expect(find.byType(EventDateBadge), findsOneWidget);
    expect(find.byKey(const ValueKey('event-time-event')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('home panels and items use distinct surfaces without nested borders', (tester) async {
    await mount(tester, posts: [post('a'), post('event', event: true)]);
    for (final id in ['a', 'event']) {
      final card = tester.widget<Card>(find.byKey(ValueKey('home-post-surface-$id')));
      expect(card.color, HiveColors.canvas);
      expect(card.elevation, 0);
      expect((card.shape! as RoundedRectangleBorder).side, BorderSide.none);
    }
    for (final section in ['announcements', 'events']) {
      final panel = tester.widget<DecoratedBox>(find.byKey(ValueKey('home-$section-panel')));
      final decoration = panel.decoration as BoxDecoration;
      expect(decoration.color, HiveColors.surface);
      expect(decoration.border!.top.color, HiveColors.divider);
      expect(decoration.border!.top.width, 1);
    }
  });

  testWidgets('calendar expansion survives refresh and breakpoint changes', (tester) async {
    var reads = 0;
    await mount(tester, handler: (_) async {
      reads++;
      if (reads == 2) return http.Response('{}', 500);
      return response([post('event', event: true)]);
    });
    final eventToggle = find.byKey(const ValueKey('event-toggle-event'));
    final eventDetails = find.byKey(const ValueKey('event-details-event'));
    await tester.tap(eventToggle);
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const Key('refresh-home')));
      await tester.pumpAndSettle();
      expect(eventDetails, findsOneWidget);
    }
    tester.view.physicalSize = const Size(320, 900);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(eventToggle, 200, scrollable: find.byType(Scrollable).first);
    expect(eventDetails, findsOneWidget);
    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();
    expect(eventDetails, findsOneWidget);
  });

  testWidgets(
    'expansion survives refresh, failure and responsive changes; removed IDs reset',
    (tester) async {
      var reads = 0;
      await mount(
        tester,
        handler: (_) async {
          reads++;
          if (reads == 2) return http.Response('{}', 500);
          if (reads == 4) return response([post('b')]);
          return response([post('a'), post('b')]);
        },
      );
      await tester.tap(toggle('a'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const Key('refresh-home')));
        await tester.pumpAndSettle();
        expect(details('a'), findsOneWidget);
      }
      tester.view.physicalSize = const Size(320, 900);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-columns')), findsNothing);
      expect(details('a'), findsOneWidget);
      tester.view.physicalSize = const Size(1200, 900);
      await tester.pumpAndSettle();
      expect(details('a'), findsOneWidget);
      await tester.tap(find.byKey(const Key('refresh-home')));
      await tester.pumpAndSettle();
      expect(toggle('a'), findsNothing);
      await tester.tap(find.byKey(const Key('refresh-home')));
      await tester.pumpAndSettle();
      expect(toggle('a'), findsOneWidget);
      expect(details('a'), findsNothing);
    },
  );

  for (final language in ['pt', 'en', 'es']) {
    for (final width in [320.0, 1200.0]) {
      testWidgets(
        'layout and empty states in $language at $width with enlarged text',
        (tester) async {
          await mount(
            tester,
            locale: Locale(language),
            width: width,
            scale: 1.6,
            posts: [post('a'), post('event', event: true)],
          );
          await tester.tap(toggle('a'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (width == 320) {
            expect(find.byType(CustomScrollView), findsOneWidget);
            await tester.scrollUntilVisible(
              find.byKey(const ValueKey('home-events-heading')),
              250,
              scrollable: find.byType(Scrollable).first,
            );
            expect(tester.takeException(), isNull);
          }
          await mount(
            tester,
            locale: Locale(language),
            width: width,
            scale: 1.6,
            posts: [],
          );
          expect(
            find.text(translations[language]!.text('home.noAnnouncements')),
            findsOneWidget,
          );
          if (width == 320) {
            await tester.scrollUntilVisible(
              find.text(translations[language]!.text('home.noEvents')),
              200,
              scrollable: find.byType(Scrollable).first,
            );
          }
          expect(
            find.text(translations[language]!.text('home.noEvents')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('mobile pull to refresh updates both sections', (tester) async {
    var calls = 0;
    await mount(
      tester,
      width: 320,
      handler: (_) async {
        calls++;
        return response([post('a')]);
      },
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('capture home desktop and mobile', (tester) async {
    for (final width in [1200.0, 320.0]) {
      await mount(
        tester,
        width: width,
        posts: [post('a'), post('b'), post('event', event: true)],
      );
      await tester.tap(toggle('a'));
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('home-preview')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/previews/home-columns-${width.toInt()}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  }, skip: !capture);
}

Future<void> mount(
  WidgetTester tester, {
  List<Object?> posts = const [],
  Future<http.Response> Function(http.Request)? handler,
  Locale locale = const Locale('pt'),
  double width = 1200,
  double scale = 1,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final client = MockClient(handler ?? (_) async => response(posts));
  addTearDown(client.close);
  final theme = HiveTheme.apply(
    ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: capture ? 'HomePreview' : null,
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
      localizationsDelegates: const [
        TestTranslations(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: capture
          ? theme.copyWith(
              textTheme: theme.textTheme.apply(fontFamily: 'HomePreview'),
              textButtonTheme: TextButtonThemeData(
                style: theme.textButtonTheme.style!.copyWith(
                  textStyle: WidgetStatePropertyAll(
                    theme.textTheme.labelLarge!.copyWith(
                      fontFamily: 'HomePreview',
                    ),
                  ),
                ),
              ),
            )
          : theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: RepaintBoundary(
        key: const Key('home-preview'),
        child: Scaffold(
          backgroundColor: HiveColors.surface,
          body: HomeScreen(
            service: CommunicationService(
              ApiClient(client: client, baseUrl: 'https://example.test'),
            ),
            session: UserSession(
              token: 'user-token',
              userId: 'u',
              buildingId: 'b',
              buildingName: 'Condomínio Demo HiveApp',
              residencyId: 'r',
              permissions: const [],
              expiresAt: DateTime.utc(2100),
            ),
            onSessionExpired: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
