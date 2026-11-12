import 'package:front_flutter/types/complaint_failure.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/types/complaint.dart';
import 'package:front_flutter/helpers/complaint_access.dart';
import 'package:front_flutter/helpers/complaints_repository.dart';
import 'package:front_flutter/lang/complaint_strings.dart';
import 'package:front_flutter/views/complaints.dart';

final _strings = ComplaintStrings.forLanguage('pt');
const _newComplaint = ValueKey('new-complaint');
const _complaintList = ValueKey('complaint-list');
const _subjectField = ValueKey('complaint-subject');
const _descriptionField = ValueKey('complaint-description');
const _submitComplaint = ValueKey('submit-complaint');
const _responseField = ValueKey('complaint-response');
const _sendResponse = ValueKey('send-response');
const _closeComplaint = ValueKey('close-complaint');

Complaint _report({
  String id = 'complaint-1',
  String title = 'Iluminação da garagem',
}) => Complaint(
  id: id,
  residencyId: 'selected-residence',
  title: title,
  description: 'A luz próxima à rampa está apagada e o trecho fica escuro.',
  createdAt: DateTime(2026, 10, 23, 19, 10),
  status: ComplaintStatus.open,
);

ComplaintAccess _access({
  bool resident = true,
  List<String> permissions = const [
    '@complaint:create',
    '@complaint:view:residency',
  ],
}) => ComplaintAccess.fromSession(
  userId: 'selected-user',
  buildingId: 'selected-building',
  permissions: permissions,
  expiresAt: DateTime.utc(2100),
  residentAccess: resident,
  residencyId: resident ? 'selected-residence' : null,
);

class _FakeRepository implements ComplaintsRepository {
  _FakeRepository({
    List<Complaint>? mine,
    List<Complaint>? building,
    this.listFailures = 0,
    this.pending = false,
    this.createFailures = 0,
    this.administrativeReplies = true,
  }) : mine = List.of(mine ?? [_report()]),
       building = List.of(building ?? mine ?? [_report()]);

  final List<Complaint> mine;
  final List<Complaint> building;
  final List<ComplaintScope> requestedScopes = [];
  final bool pending;
  int listFailures;
  int createFailures;
  final bool administrativeReplies;
  int createCalls = 0;
  int respondCalls = 0;
  int closeCalls = 0;
  String? lastTitle;
  String? lastDescription;
  String? lastResponse;
  String? lastRespondedId;
  String? lastClosedId;

  @override
  Future<List<Complaint>> list({
    required ComplaintScope scope,
    ComplaintStatus? status,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    if (pending) return Completer<List<Complaint>>().future;
    requestedScopes.add(scope);
    if (listFailures > 0) {
      listFailures--;
      throw StateError('Simulated list failure');
    }
    return List.of(scope == ComplaintScope.mine ? mine : building);
  }

  @override
  Future<Complaint> create({
    required String title,
    required String category,
    required String description,
  }) async {
    createCalls++;
    lastTitle = title;
    lastDescription = description;
    if (createFailures > 0) {
      createFailures--;
      throw StateError('Simulated create failure');
    }
    final created = Complaint(
      id: 'created-$createCalls',
      title: title,
      category: category,
      description: description,
      createdAt: DateTime(2026, 10, 25, 14, 30),
      status: ComplaintStatus.open,
    );
    mine.insert(0, created);
    building.insert(0, created);
    return created;
  }

  @override
  Future<Complaint> respond({
    required String complaintId,
    required String message,
  }) async {
    respondCalls++;
    lastRespondedId = complaintId;
    lastResponse = message;
    final existing = building.firstWhere((item) => item.id == complaintId);
    final updated = existing.copyWith(
      status: ComplaintStatus.open,
      responses: [
        ...existing.responses,
        ComplaintResponse(
          message: message,
          isAdministrative: administrativeReplies,
          createdAt: DateTime(2026, 10, 25, 14, 35),
        ),
      ],
    );
    _replace(updated);
    return updated;
  }

  @override
  Future<Complaint> getDetail(String id) async =>
      [...mine, ...building].firstWhere((item) => item.id == id);

  @override
  Future<Complaint> changeStatus({
    required String complaintId,
    required ComplaintStatus status,
  }) async {
    if (status == ComplaintStatus.closed) {
      closeCalls++;
      lastClosedId = complaintId;
    }
    final updated = building
        .firstWhere((item) => item.id == complaintId)
        .copyWith(status: status);
    _replace(updated);
    return updated;
  }

  @override
  Future<Complaint> close({required String complaintId}) async {
    closeCalls++;
    lastClosedId = complaintId;
    final updated = building
        .firstWhere((item) => item.id == complaintId)
        .copyWith(status: ComplaintStatus.closed);
    _replace(updated);
    return updated;
  }

  void _replace(Complaint updated) {
    for (final collection in [mine, building]) {
      final index = collection.indexWhere((item) => item.id == updated.id);
      if (index >= 0) collection[index] = updated;
    }
  }
}

Future<void> _mount(
  WidgetTester tester, {
  required _FakeRepository repository,
  required ComplaintAccess access,
  Size size = const Size(1280, 900),
  Brightness brightness = Brightness.dark,
  double textScale = 1,
  VoidCallback? onSignIn,
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness, useMaterial3: true),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: ComplaintsView(
          access: access,
          repository: repository,
          buildingName: 'Condomínio Jardim das Flores',
          strings: ComplaintStrings.forLanguage('pt'),
          onSignIn: onSignIn,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _selectReport(WidgetTester tester, String subject) async {
  await _tapVisible(
    tester,
    find.descendant(
      of: find.byKey(_complaintList),
      matching: find.text(subject),
    ),
  );
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  for (final width in [390.0, 1280.0]) {
    for (final state in [
      'list',
      'detail',
      'create',
      'empty',
      'error',
      'loading',
    ]) {
      testWidgets('visual baseline ${width.toInt()} $state', (tester) async {
        final repository = _FakeRepository(
          mine: state == 'empty' ? [] : null,
          listFailures: state == 'error' ? 1 : 0,
          pending: state == 'loading',
        );
        await _mount(
          tester,
          repository: repository,
          access: _access(permissions: ['@core:admin']),
          size: Size(width, 900),
          settle: state != 'loading',
        );
        if (state == 'detail') {
          await _selectReport(tester, 'Iluminação da garagem');
        }
        if (state == 'create') {
          await _tapVisible(tester, find.byKey(_newComplaint));
        }
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('goldens/complaints-${width.toInt()}-$state.png'),
        );
        await _finish(tester);
      });
    }
  }

  testWidgets('sem permissao nao consulta nem cadastra reclamacoes', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _mount(
      tester,
      repository: repository,
      access: _access(permissions: []),
    );
    expect(repository.requestedScopes, isEmpty);
    expect(find.byKey(_newComplaint), findsNothing);
    expect(find.byKey(_complaintList), findsNothing);
    expect(find.text(_strings.text('deniedTitle')), findsOneWidget);
    await _finish(tester);
  });

  testWidgets('view residencia nao concede criar responder ou alterar status', (
    tester,
  ) async {
    await _mount(
      tester,
      repository: _FakeRepository(),
      access: _access(permissions: ['@complaint:view:residency']),
    );
    expect(find.byKey(_newComplaint), findsNothing);
    await _selectReport(tester, _report().title);
    expect(find.byKey(_responseField), findsNothing);
    expect(find.byKey(_closeComplaint), findsNothing);
    await _finish(tester);
  });

  testWidgets(
    'morador com respond residencia responde sem acoes administrativas',
    (tester) async {
      final repository = _FakeRepository(administrativeReplies: false);
      await _mount(
        tester,
        repository: repository,
        access: _access(
          permissions: [
            '@complaint:view:residency',
            '@complaint:respond:residency',
          ],
        ),
      );
      await _selectReport(tester, _report().title);
      await tester.ensureVisible(find.byKey(_responseField));
      await tester.enterText(
        find.byKey(_responseField),
        'Complemento da residencia',
      );
      tester.testTextInput.hide();
      await _tapVisible(tester, find.byKey(_sendResponse));
      expect(repository.respondCalls, 1);
      expect(repository.mine.first.responses.single.isAdministrative, isFalse);
      expect(find.byKey(_newComplaint), findsNothing);
      expect(find.byKey(_closeComplaint), findsNothing);
      expect(find.text(_strings.text('responseFromResidency')), findsOneWidget);
      await _finish(tester);
    },
  );

  testWidgets(
    'update status nao concede responder nem aceita resposta de morador para encerrar',
    (tester) async {
      final report = _report().copyWith(
        responses: [
          ComplaintResponse(
            message: 'Complemento',
            createdAt: DateTime.utc(2026),
            isAdministrative: false,
          ),
        ],
      );
      await _mount(
        tester,
        repository: _FakeRepository(building: [report]),
        access: _access(
          resident: false,
          permissions: ['@complaint:view:building', '@complaint:update:status'],
        ),
      );
      await _selectReport(tester, report.title);
      expect(find.byKey(_responseField), findsNothing);
      expect(find.byKey(_newComplaint), findsNothing);
      expect(
        tester.widget<TextButton>(find.byKey(_closeComplaint)).onPressed,
        isNull,
      );
      expect(find.text(_strings.text('markInAnalysis')), findsOneWidget);
      await _finish(tester);
    },
  );

  testWidgets(
    'create com building sem residencia ou view abre apenas formulario',
    (tester) async {
      final repository = _FakeRepository();
      await _mount(
        tester,
        repository: repository,
        access: _access(resident: false, permissions: ['@complaint:create']),
      );
      expect(repository.requestedScopes, isEmpty);
      expect(find.byKey(_subjectField), findsOneWidget);
      expect(find.byKey(_complaintList), findsNothing);
      await tester.enterText(find.byKey(_subjectField), 'Registro do predio');
      await tester.enterText(
        find.byKey(_descriptionField),
        'Criacao autorizada pelo building do token.',
      );
      tester.testTextInput.hide();
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('complaint-category')),
      );
      await _tapVisible(tester, find.text('Outros').last);
      await _tapVisible(tester, find.byKey(_submitComplaint));
      expect(repository.createCalls, 1);
      expect(repository.requestedScopes, isEmpty);
      expect(
        tester
            .widget<TextFormField>(find.byKey(_subjectField))
            .controller!
            .text,
        isEmpty,
      );
      await _finish(tester);
    },
  );

  testWidgets('morador consulta próprias, cria e não recebe ações de gestão', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _mount(tester, repository: repository, access: _access());

    expect(repository.requestedScopes, [ComplaintScope.mine]);
    expect(find.text(_strings.text('title')), findsOneWidget);
    expect(find.byKey(_newComplaint), findsOneWidget);
    await _selectReport(tester, _report().title);
    expect(find.text(_strings.text('report')), findsOneWidget);
    expect(find.byKey(_responseField), findsNothing);
    expect(find.byKey(_sendResponse), findsNothing);
    expect(find.byKey(_closeComplaint), findsNothing);
    expect(find.byType(CircleAvatar), findsNothing);

    await _tapVisible(tester, find.byKey(_newComplaint));
    await tester.enterText(find.byKey(_subjectField), 'Portão com defeito');
    await tester.enterText(
      find.byKey(_descriptionField),
      'O portão de pedestres não fecha por completo.',
    );
    tester.testTextInput.hide();
    await _tapVisible(tester, find.byKey(const ValueKey('complaint-category')));
    await _tapVisible(tester, find.text('Outros').last);
    await _tapVisible(tester, find.byKey(_submitComplaint));

    expect(repository.createCalls, 1);
    expect(repository.lastTitle, 'Portão com defeito');
    expect(find.byKey(_subjectField), findsNothing);
    expect(find.text('Portão com defeito'), findsWidgets);
    expect(find.textContaining('REC-2026-0200'), findsNothing);
    expect(find.byKey(_responseField), findsNothing);
    expect(find.byKey(_closeComplaint), findsNothing);
    expect(tester.takeException(), isNull);
    await _finish(tester);
  });

  testWidgets('administração responde e só encerra após confirmar', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _mount(
      tester,
      repository: repository,
      access: _access(
        resident: false,
        permissions: [
          '@complaint:view:building',
          '@complaint:respond:building',
          '@complaint:update:status',
        ],
      ),
    );
    expect(repository.requestedScopes, [ComplaintScope.building]);
    expect(find.text(_strings.text('title')), findsOneWidget);
    expect(find.byKey(_newComplaint), findsNothing);
    await _selectReport(tester, _report().title);
    await _tapVisible(tester, find.byKey(_sendResponse));
    expect(repository.respondCalls, 0);
    expect(find.text(_strings.text('requiredResponse')), findsOneWidget);

    await tester.ensureVisible(find.byKey(_responseField));
    await tester.enterText(
      find.byKey(_responseField),
      '  A manutenção fará a troca amanhã.  ',
    );
    tester.testTextInput.hide();
    await _tapVisible(tester, find.byKey(_sendResponse));
    expect(repository.respondCalls, 1);
    expect(repository.lastRespondedId, _report().id);
    expect(repository.lastResponse, 'A manutenção fará a troca amanhã.');
    expect(find.text('A manutenção fará a troca amanhã.'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byKey(_responseField)).controller!.text,
      isEmpty,
    );

    ScaffoldMessenger.of(tester.element(find.byType(ComplaintsView)))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.byKey(_closeComplaint));
    expect(repository.closeCalls, 0);
    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    await _tapVisible(
      tester,
      find.descendant(
        of: dialog,
        matching: find.widgetWithText(TextButton, _strings.text('cancel')),
      ),
    );
    expect(repository.closeCalls, 0);
    expect(find.byKey(_responseField), findsOneWidget);

    await _tapVisible(tester, find.byKey(_closeComplaint));
    await _tapVisible(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(
          FilledButton,
          _strings.text('confirmClose'),
        ),
      ),
    );
    expect(repository.closeCalls, 1);
    expect(repository.lastClosedId, _report().id);
    expect(find.byKey(_responseField), findsNothing);
    expect(find.byKey(_sendResponse), findsNothing);
    expect(find.byKey(_closeComplaint), findsNothing);
    expect(find.text(_strings.text('closedMessage')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _finish(tester);
  });

  for (final resident in [false, true]) {
    testWidgets(
      'core admin administra sem permissão específica: residente=$resident',
      (tester) async {
        final repository = _FakeRepository();
        await _mount(
          tester,
          repository: repository,
          access: _access(
            resident: resident,
            permissions: ['@coreadmin', '@core:admin'],
          ),
        );
        expect(repository.requestedScopes, [ComplaintScope.building]);
        expect(find.text(_strings.text('title')), findsOneWidget);
        await _selectReport(tester, _report().title);
        expect(find.byKey(_responseField), findsOneWidget);
        expect(find.byKey(_sendResponse), findsOneWidget);
        expect(find.byKey(_closeComplaint), findsOneWidget);
        expect(repository.respondCalls, 0);
        expect(repository.closeCalls, 0);
        await _finish(tester);
      },
    );
  }

  for (final signedIn in [false, true]) {
    testWidgets('gate sem dados ou consulta: sessão=$signedIn', (tester) async {
      final repository = _FakeRepository();
      var signInCalls = 0;
      await _mount(
        tester,
        repository: repository,
        access: signedIn
            ? const ComplaintAccess.denied()
            : const ComplaintAccess.signedOut(),
        onSignIn: () => signInCalls++,
      );
      expect(repository.requestedScopes, isEmpty);
      expect(repository.createCalls, 0);
      expect(find.byKey(_newComplaint), findsNothing);
      expect(find.byKey(_complaintList), findsNothing);
      expect(find.text(_report().title), findsNothing);
      expect(
        find.text(_strings.text(signedIn ? 'deniedTitle' : 'signedOutTitle')),
        findsOneWidget,
      );
      if (!signedIn) {
        await _tapVisible(tester, find.text(_strings.text('signIn')));
        expect(signInCalls, 1);
      } else {
        expect(find.text(_strings.text('signIn')), findsNothing);
      }
      expect(tester.takeException(), isNull);
      await _finish(tester);
    });
  }

  testWidgets('vazio é distinto de uma falha de leitura', (tester) async {
    final repository = _FakeRepository(mine: []);
    await _mount(tester, repository: repository, access: _access());
    expect(find.text(_strings.text('emptyTitle')), findsOneWidget);
    expect(find.text(_strings.text('loadError')), findsNothing);
    expect(find.text(_strings.text('retry')), findsNothing);
    expect(find.byKey(_newComplaint), findsOneWidget);
    await _finish(tester);
  });

  testWidgets('falha de leitura permite repetir sem exibir vazio', (
    tester,
  ) async {
    final repository = _FakeRepository(listFailures: 1);
    await _mount(tester, repository: repository, access: _access());
    expect(
      find.text(_strings.failure(ComplaintFailure.server)),
      findsOneWidget,
    );
    expect(find.text(_strings.text('emptyTitle')), findsNothing);
    await _tapVisible(tester, find.text(_strings.text('retry')));
    expect(repository.requestedScopes, [
      ComplaintScope.mine,
      ComplaintScope.mine,
    ]);
    expect(find.text(_strings.text('loadError')), findsNothing);
    expect(find.byKey(_complaintList), findsOneWidget);
    expect(find.text(_report().title), findsOneWidget);
    await _finish(tester);
  });

  testWidgets('criação valida campos e preserva o rascunho após falha', (
    tester,
  ) async {
    final repository = _FakeRepository(createFailures: 1);
    await _mount(tester, repository: repository, access: _access());
    await _tapVisible(tester, find.byKey(_newComplaint));
    await _tapVisible(tester, find.byKey(_submitComplaint));
    expect(repository.createCalls, 0);
    expect(find.text(_strings.text('requiredSubject')), findsOneWidget);
    expect(find.text(_strings.text('requiredDescription')), findsOneWidget);

    const subject = '  Ruído na área comum  ';
    const description = '  Houve barulho após as 22h.\nPeço uma verificação.  ';
    await tester.enterText(find.byKey(_subjectField), subject);
    await tester.enterText(find.byKey(_descriptionField), description);
    tester.testTextInput.hide();
    await _tapVisible(tester, find.byKey(const ValueKey('complaint-category')));
    await _tapVisible(tester, find.text('Outros').last);
    await _tapVisible(tester, find.byKey(_submitComplaint));
    expect(repository.createCalls, 1);
    expect(find.text(_strings.text('mutationError')), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byKey(_subjectField)).controller!.text,
      subject,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(_descriptionField))
          .controller!
          .text,
      description,
    );
    await _tapVisible(tester, find.byKey(_submitComplaint));
    expect(repository.createCalls, 2);
    expect(repository.lastTitle, subject.trim());
    expect(repository.lastDescription, description.trim());
    expect(find.byKey(_submitComplaint), findsNothing);
    expect(find.text(subject.trim()), findsWidgets);
    expect(tester.takeException(), isNull);
    await _finish(tester);
  });

  testWidgets('compacto expande e recolhe o detalhe sem esconder a lista', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _mount(
      tester,
      repository: repository,
      access: _access(),
      size: const Size(320, 800),
    );
    expect(find.byKey(_complaintList), findsOneWidget);
    expect(find.text(_strings.text('report')), findsNothing);
    await _selectReport(tester, _report().title);
    expect(find.byKey(_complaintList), findsOneWidget);
    expect(find.text(_strings.text('report')), findsOneWidget);
    expect(find.text(_report().description), findsOneWidget);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('complaint-toggle-complaint-1')),
    );
    expect(find.byKey(_complaintList), findsOneWidget);
    expect(find.text(_strings.text('report')), findsNothing);
    expect(tester.takeException(), isNull);
    await _finish(tester);
  });

  for (final width in [320.0, 1280.0, 1800.0]) {
    for (final manager in [false, true]) {
      testWidgets('lista ocupa o quadro e expande um item: '
          'largura=$width gestão=$manager', (tester) async {
        final repository = _FakeRepository(
          mine: [
            _report(),
            _report(id: 'complaint-2', title: 'Vazamento no corredor'),
          ],
        );
        await _mount(
          tester,
          repository: repository,
          access: _access(
            permissions: manager
                ? ['@core:admin']
                : ['@complaint:create', '@complaint:view:residency'],
          ),
          size: Size(width, 900),
        );
        final list = find.byKey(_complaintList);
        expect(
          tester.getSize(list).width,
          closeTo(width - (width < 768 ? 32 : 64), 1),
        );
        expect(find.text(_strings.text('selectTitle')), findsNothing);
        expect(find.byKey(_responseField), findsNothing);

        await _tapVisible(
          tester,
          find.byKey(const ValueKey('complaint-toggle-complaint-1')),
        );
        expect(list, findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('complaint-item-complaint-1')),
            matching: find.byKey(
              const ValueKey('complaint-expanded-complaint-1'),
            ),
          ),
          findsOneWidget,
        );
        expect(find.text('Vazamento no corredor'), findsOneWidget);
        expect(
          find.byKey(_responseField),
          manager ? findsOneWidget : findsNothing,
        );

        await _tapVisible(
          tester,
          find.byKey(const ValueKey('complaint-toggle-complaint-2')),
        );
        expect(
          find.byKey(const ValueKey('complaint-expanded-complaint-1')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('complaint-expanded-complaint-2')),
          findsOneWidget,
        );
        await _tapVisible(
          tester,
          find.byKey(const ValueKey('complaint-toggle-complaint-2')),
        );
        expect(find.text(_strings.text('report')), findsNothing);
        expect(list, findsOneWidget);
        expect(tester.takeException(), isNull);
        await _finish(tester);
      });
    }
  }

  for (final width in [320.0, 1280.0]) {
    for (final manager in [false, true]) {
      testWidgets('cadastro independe da visao e cancelar retorna: '
          'largura=$width gestão=$manager', (tester) async {
        await _mount(
          tester,
          repository: _FakeRepository(),
          access: _access(
            permissions: manager
                ? ['@core:admin']
                : ['@complaint:create', '@complaint:view:residency'],
          ),
          size: Size(width, 900),
        );
        final scopes = manager
            ? [ComplaintScope.building, ComplaintScope.mine]
            : [ComplaintScope.mine];
        for (final scope in scopes) {
          if (manager) {
            await _tapVisible(tester, find.text(_strings.text(scope.name)));
          }
          expect(
            tester.widget<FilledButton>(find.byKey(_newComplaint)).onPressed,
            isNotNull,
          );
          await _tapVisible(tester, find.byKey(_newComplaint));
          expect(find.byKey(_subjectField), findsOneWidget);
          expect(find.byKey(_descriptionField), findsOneWidget);
          expect(find.byKey(_complaintList), findsNothing);
          expect(find.byKey(const ValueKey('status-null')), findsNothing);
          expect(find.text(_strings.text('building')), findsNothing);
          expect(find.text(_strings.text('refresh')), findsNothing);
          await _tapVisible(tester, find.text(_strings.text('cancel')));
          expect(find.byKey(_complaintList), findsOneWidget);
          expect(find.byKey(_subjectField), findsNothing);
        }
        expect(tester.takeException(), isNull);
        await _finish(tester);
      });
    }
  }

  testWidgets(
    'recolher atendimento confirma descarte da resposta em rascunho',
    (tester) async {
      await _mount(
        tester,
        repository: _FakeRepository(),
        access: _access(permissions: ['@core:admin']),
      );
      final toggle = find.byKey(const ValueKey('complaint-toggle-complaint-1'));
      await _tapVisible(tester, toggle);
      await tester.ensureVisible(find.byKey(_responseField));
      await tester.enterText(
        find.byKey(_responseField),
        'Resposta em rascunho',
      );
      tester.testTextInput.hide();
      await _tapVisible(tester, toggle);
      expect(find.byType(AlertDialog), findsOneWidget);
      await _tapVisible(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(_strings.text('cancel')),
        ),
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(_responseField))
            .controller!
            .text,
        'Resposta em rascunho',
      );
      await _tapVisible(tester, toggle);
      await _tapVisible(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(_strings.text('discardConfirm')),
        ),
      );
      expect(find.byKey(_responseField), findsNothing);
      expect(find.byKey(_complaintList), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _finish(tester);
    },
  );

  for (final size in [const Size(320, 800), const Size(1280, 900)]) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.0, 2.0]) {
        for (final manager in [false, true]) {
          testWidgets('layout ${size.width.toInt()}x${size.height.toInt()} '
              '${brightness.name} texto=$scale gestão=$manager', (
            tester,
          ) async {
            final report = _report(
              title: 'Iluminação insuficiente no corredor próximo à garagem',
            );
            final repository = _FakeRepository(mine: [report]);
            await _mount(
              tester,
              repository: repository,
              access: manager
                  ? _access(
                      resident: false,
                      permissions: [
                        '@complaint:view:building',
                        '@complaint:respond:building',
                        '@complaint:update:status',
                      ],
                    )
                  : _access(),
              size: size,
              brightness: brightness,
              textScale: scale,
            );
            expect(tester.takeException(), isNull);
            await _selectReport(tester, report.title);
            expect(tester.takeException(), isNull);
            if (manager) {
              await tester.ensureVisible(find.byKey(_responseField));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(
                tester
                    .widget<TextButton>(find.byKey(_closeComplaint))
                    .onPressed,
                isNull,
              );
            } else {
              await _tapVisible(tester, find.byKey(_newComplaint));
              expect(find.byKey(_subjectField), findsOneWidget);
              expect(find.byKey(_descriptionField), findsOneWidget);
              await tester.ensureVisible(find.byKey(_submitComplaint));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
            await _finish(tester);
          });
        }
      }
    }
  }
}
