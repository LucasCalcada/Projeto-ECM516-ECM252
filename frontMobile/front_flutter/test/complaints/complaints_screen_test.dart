import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/features/complaints/domain/complaint.dart';
import 'package:front_flutter/features/complaints/domain/complaint_access.dart';
import 'package:front_flutter/features/complaints/domain/complaints_repository.dart';
import 'package:front_flutter/features/complaints/presentation/complaint_strings.dart';
import 'package:front_flutter/features/complaints/presentation/complaints_screen.dart';

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
  String subject = 'Iluminação da garagem',
}) => Complaint(
  id: id,
  protocol: 'REC-2026-0102',
  subject: subject,
  description: 'A luz próxima à rampa está apagada e o trecho fica escuro.',
  createdAt: DateTime(2026, 10, 23, 19, 10),
  status: ComplaintStatus.open,
);

ComplaintAccess _access({
  bool resident = true,
  List<String> permissions = const [],
}) => ComplaintAccess.fromSession(
  userId: 'selected-user',
  buildingId: 'selected-building',
  permissions: permissions,
  expiresAt: DateTime.utc(2100),
  residentAccess: resident,
);

class _FakeRepository implements ComplaintsRepository {
  _FakeRepository({
    List<Complaint>? mine,
    List<Complaint>? building,
    this.listFailures = 0,
    this.createFailures = 0,
  }) : mine = List.of(mine ?? [_report()]),
       building = List.of(building ?? mine ?? [_report()]);

  final List<Complaint> mine;
  final List<Complaint> building;
  final List<ComplaintScope> requestedScopes = [];
  int listFailures;
  int createFailures;
  int createCalls = 0;
  int respondCalls = 0;
  int closeCalls = 0;
  String? lastSubject;
  String? lastDescription;
  String? lastResponse;
  String? lastRespondedId;
  String? lastClosedId;

  @override
  Future<List<Complaint>> list({required ComplaintScope scope}) async {
    requestedScopes.add(scope);
    if (listFailures > 0) {
      listFailures--;
      throw StateError('Simulated list failure');
    }
    return List.of(scope == ComplaintScope.mine ? mine : building);
  }

  @override
  Future<Complaint> create({
    required String subject,
    required String description,
  }) async {
    createCalls++;
    lastSubject = subject;
    lastDescription = description;
    if (createFailures > 0) {
      createFailures--;
      throw StateError('Simulated create failure');
    }
    final created = Complaint(
      id: 'created-$createCalls',
      protocol: 'REC-2026-0200',
      subject: subject,
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
      status: ComplaintStatus.answered,
      responses: [
        ...existing.responses,
        ComplaintResponse(
          message: message,
          createdAt: DateTime(2026, 10, 25, 14, 35),
        ),
      ],
    );
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
  Brightness brightness = Brightness.light,
  double textScale = 1,
  VoidCallback? onSignIn,
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
        body: ComplaintsScreen(
          access: access,
          repository: repository,
          buildingName: 'Condomínio Jardim das Flores',
          languageCode: 'pt',
          onSignIn: onSignIn,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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
  testWidgets('morador consulta próprias, cria e não recebe ações de gestão', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _mount(tester, repository: repository, access: _access());

    expect(repository.requestedScopes, [ComplaintScope.mine]);
    expect(find.text(_strings.text('titleResident')), findsOneWidget);
    expect(find.byKey(_newComplaint), findsOneWidget);
    await _selectReport(tester, _report().subject);
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
    await _tapVisible(tester, find.byKey(_submitComplaint));

    expect(repository.createCalls, 1);
    expect(repository.lastSubject, 'Portão com defeito');
    expect(find.byKey(_subjectField), findsNothing);
    expect(find.text('Portão com defeito'), findsWidgets);
    expect(find.textContaining('REC-2026-0200'), findsWidgets);
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
      access: _access(resident: false, permissions: ['@complaint:manage']),
    );
    expect(repository.requestedScopes, [ComplaintScope.building]);
    expect(find.text(_strings.text('titleManager')), findsOneWidget);
    expect(find.byKey(_newComplaint), findsNothing);
    await _selectReport(tester, _report().subject);
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

    ScaffoldMessenger.of(tester.element(find.byType(ComplaintsScreen)))
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
    testWidgets('coreadmin sem permissão de reclamações: residente=$resident', (
      tester,
    ) async {
      final repository = _FakeRepository();
      await _mount(
        tester,
        repository: repository,
        access: _access(
          resident: resident,
          permissions: ['@coreadmin', '@core:admin'],
        ),
      );
      expect(find.text(_strings.text('titleManager')), findsNothing);
      if (resident) {
        expect(repository.requestedScopes, [ComplaintScope.mine]);
        await _selectReport(tester, _report().subject);
      } else {
        expect(repository.requestedScopes, isEmpty);
        expect(find.text(_strings.text('deniedTitle')), findsOneWidget);
      }
      expect(find.byKey(_responseField), findsNothing);
      expect(find.byKey(_sendResponse), findsNothing);
      expect(find.byKey(_closeComplaint), findsNothing);
      expect(repository.respondCalls, 0);
      expect(repository.closeCalls, 0);
      await _finish(tester);
    });
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
      expect(find.text(_report().subject), findsNothing);
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
    expect(find.text(_strings.text('loadError')), findsOneWidget);
    expect(find.text(_strings.text('emptyTitle')), findsNothing);
    await _tapVisible(tester, find.text(_strings.text('retry')));
    expect(repository.requestedScopes, [
      ComplaintScope.mine,
      ComplaintScope.mine,
    ]);
    expect(find.text(_strings.text('loadError')), findsNothing);
    expect(find.byKey(_complaintList), findsOneWidget);
    expect(find.text(_report().subject), findsOneWidget);
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
    expect(repository.lastSubject, subject.trim());
    expect(repository.lastDescription, description.trim());
    expect(find.byKey(_submitComplaint), findsNothing);
    expect(find.text(subject.trim()), findsWidgets);
    expect(tester.takeException(), isNull);
    await _finish(tester);
  });

  testWidgets('compacto navega da lista ao detalhe e retorna à lista', (
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
    await _selectReport(tester, _report().subject);
    expect(find.byKey(_complaintList), findsNothing);
    expect(find.text(_strings.text('report')), findsOneWidget);
    expect(find.text(_report().description), findsOneWidget);
    await _tapVisible(tester, find.text(_strings.text('backToList')));
    expect(find.byKey(_complaintList), findsOneWidget);
    expect(find.text(_strings.text('report')), findsNothing);
    expect(tester.takeException(), isNull);
    await _finish(tester);
  });

  for (final size in [const Size(320, 800), const Size(1280, 900)]) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.0, 2.0]) {
        for (final manager in [false, true]) {
          testWidgets('layout ${size.width.toInt()}x${size.height.toInt()} '
              '${brightness.name} texto=$scale gestão=$manager', (
            tester,
          ) async {
            final report = _report(
              subject: 'Iluminação insuficiente no corredor próximo à garagem',
            );
            final repository = _FakeRepository(mine: [report]);
            await _mount(
              tester,
              repository: repository,
              access: manager
                  ? _access(resident: false, permissions: ['@complaint:manage'])
                  : _access(),
              size: size,
              brightness: brightness,
              textScale: scale,
            );
            expect(tester.takeException(), isNull);
            await _selectReport(tester, report.subject);
            expect(tester.takeException(), isNull);
            if (manager) {
              await tester.ensureVisible(find.byKey(_responseField));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              await _tapVisible(tester, find.byKey(_closeComplaint));
              expect(find.byType(AlertDialog), findsOneWidget);
              expect(tester.takeException(), isNull);
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
