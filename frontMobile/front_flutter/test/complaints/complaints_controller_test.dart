import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/features/complaints/application/complaints_controller.dart';
import 'package:front_flutter/features/complaints/domain/complaint.dart';
import 'package:front_flutter/features/complaints/domain/complaint_access.dart';
import 'package:front_flutter/features/complaints/domain/complaints_repository.dart';

ComplaintAccess _access({
  String userId = 'resident-a',
  String buildingId = 'building-a',
  List<String> permissions = const [],
  bool residentAccess = true,
  DateTime? expiresAt,
}) => ComplaintAccess.fromSession(
  userId: userId,
  buildingId: buildingId,
  permissions: permissions,
  residentAccess: residentAccess,
  expiresAt: expiresAt ?? DateTime.now().add(const Duration(hours: 1)),
);

Complaint _complaint({
  String id = 'complaint-1',
  ComplaintStatus status = ComplaintStatus.open,
}) => Complaint(
  id: id,
  protocol: 'REC-001',
  subject: 'Iluminação da garagem',
  description: 'As lâmpadas do corredor estão apagadas.',
  createdAt: DateTime.utc(2026, 10, 25, 12),
  status: status,
);

void main() {
  group('presentation access', () {
    test('resident reads and creates only in the personal scope', () {
      final access = _access();
      expect(access.isSignedIn, isTrue);
      expect(access.canRead, isTrue);
      expect(access.canCreate, isTrue);
      expect(access.canManage, isFalse);
      expect(access.scope, ComplaintScope.mine);
    });

    test('only complaint manage enables building management', () {
      final manager = _access(
        permissions: ['@complaint:manage'],
        residentAccess: false,
      );
      final coreAdmin = _access(
        permissions: ['@core:admin'],
        residentAccess: false,
      );
      expect(manager.canRead, isTrue);
      expect(manager.canManage, isTrue);
      expect(manager.canCreate, isFalse);
      expect(manager.scope, ComplaintScope.building);
      expect(_access(permissions: ['@complaint:manage']).canCreate, isFalse);
      expect(coreAdmin.canRead, isFalse);
      expect(coreAdmin.canManage, isFalse);
    });

    test('missing and expired sessions never grant actions', () {
      final expired = _access(
        permissions: ['@complaint:manage'],
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      for (final access in [
        const ComplaintAccess.signedOut(),
        const ComplaintAccess.denied(),
        expired,
        _access(userId: ''),
        _access(buildingId: ''),
      ]) {
        expect(access.canRead, isFalse);
        expect(access.canCreate, isFalse);
        expect(access.canManage, isFalse);
      }
      expect(expired.isExpired, isTrue);
      expect(const ComplaintAccess.denied().isSignedIn, isTrue);
    });

    test('session identity is stable and permission input cannot escalate', () {
      final permissions = <String>[];
      final expiry = DateTime.utc(2030);
      final access = _access(permissions: permissions, expiresAt: expiry);
      final originalIdentity = access.sessionIdentity;
      permissions.add('@complaint:manage');
      expect(access.canManage, isFalse);
      expect(access.sessionIdentity, originalIdentity);
      expect(
        _access(userId: 'resident-b', expiresAt: expiry).sessionIdentity,
        isNot(originalIdentity),
      );
      expect(access.expiresAt, expiry);
    });
  });

  group('controller', () {
    late _FakeRepository repository;
    late ComplaintsController controller;

    setUp(() {
      repository = _FakeRepository();
      controller = ComplaintsController(
        repository: repository,
        access: _access(),
      );
    });

    tearDown(() => controller.dispose());

    test(
      'resident load requests personal scope and manager requests building',
      () async {
        await controller.load();
        expect(repository.lastScope, ComplaintScope.mine);
        controller.updateAccess(_access(permissions: ['@complaint:manage']));
        expect(controller.items, isEmpty);
        expect(repository.listCalls, 1);
        await controller.load();
        expect(repository.lastScope, ComplaintScope.building);
      },
    );

    test('signed out and denied access never call the repository', () async {
      for (final access in [
        const ComplaintAccess.signedOut(),
        const ComplaintAccess.denied(),
      ]) {
        controller.updateAccess(access);
        await controller.load();
        expect(await controller.create('Assunto', 'Descrição'), isFalse);
        expect(await controller.respond('Resposta'), isFalse);
        expect(await controller.close(), isFalse);
      }
      expect(repository.listCalls, 0);
      expect(repository.createCalls, 0);
      expect(repository.respondCalls, 0);
      expect(repository.closeCalls, 0);
    });

    test('initial failure differs from a successful empty list', () async {
      repository.onList = (_) => Future.error(StateError('unavailable'));
      await controller.load();
      expect(controller.items, isEmpty);
      expect(controller.loadFailed, isTrue);
      expect(controller.isLoading, isFalse);
      repository.onList = (_) async => [];
      await controller.load();
      expect(controller.items, isEmpty);
      expect(controller.loadFailed, isFalse);
    });

    test(
      'refresh failure preserves data and selection in the same session',
      () async {
        await controller.load();
        controller.select('complaint-1');
        repository.onList = (_) => Future.error(StateError('unavailable'));
        await controller.load();
        expect(controller.loadFailed, isTrue);
        expect(controller.items.single.id, 'complaint-1');
        expect(controller.selected?.id, 'complaint-1');
      },
    );

    test('resident and core admin cannot reply or close', () async {
      for (final access in [
        _access(),
        _access(permissions: ['@core:admin']),
      ]) {
        controller.updateAccess(access);
        await controller.load();
        controller.select('complaint-1');
        expect(await controller.respond('Resposta'), isFalse);
        expect(await controller.close(), isFalse);
      }
      expect(repository.respondCalls, 0);
      expect(repository.closeCalls, 0);
    });

    test(
      'manager can respond and then close but cannot change closed items',
      () async {
        controller.updateAccess(_access(permissions: ['@complaint:manage']));
        await controller.load();
        controller.select('complaint-1');
        expect(await controller.respond('  Será verificado.  '), isTrue);
        expect(repository.lastMessage, 'Será verificado.');
        expect(controller.selected?.status, ComplaintStatus.answered);
        expect(
          controller.selected?.responses.single.message,
          'Será verificado.',
        );
        expect(await controller.close(), isTrue);
        expect(controller.selected?.status, ComplaintStatus.closed);
        expect(await controller.respond('Outra resposta'), isFalse);
        expect(await controller.close(), isFalse);
        expect(repository.respondCalls, 1);
        expect(repository.closeCalls, 1);
      },
    );

    test('create trims text, inserts and selects the result', () async {
      expect(await controller.create('  Assunto  ', '  Descrição  '), isTrue);
      expect(repository.lastSubject, 'Assunto');
      expect(repository.lastDescription, 'Descrição');
      expect(controller.items.single.id, 'created');
      expect(controller.selected?.id, 'created');
      expect(await controller.create(' ', 'Descrição'), isFalse);
      expect(repository.createCalls, 1);
    });

    test(
      'duplicate submission is blocked while the first is pending',
      () async {
        final pending = Completer<Complaint>();
        repository.onCreate = () => pending.future;
        final first = controller.create('Assunto', 'Descrição');
        expect(controller.isSubmitting, isTrue);
        expect(await controller.create('Assunto', 'Descrição'), isFalse);
        expect(repository.createCalls, 1);
        pending.complete(_complaint(id: 'created'));
        expect(await first, isTrue);
        expect(controller.isSubmitting, isFalse);
      },
    );

    test('failed mutation keeps selected data and permits a retry', () async {
      controller.updateAccess(_access(permissions: ['@complaint:manage']));
      await controller.load();
      controller.select('complaint-1');
      repository.onRespond = () => Future.error(StateError('unavailable'));
      expect(await controller.respond('Rascunho'), isFalse);
      expect(controller.mutationFailed, isTrue);
      expect(controller.selected?.status, ComplaintStatus.open);
      repository.onRespond = null;
      expect(await controller.respond('Rascunho'), isTrue);
      expect(controller.mutationFailed, isFalse);
    });

    test('session change discards an older read response', () async {
      final pending = Completer<List<Complaint>>();
      repository.onList = (_) => pending.future;
      final previousLoad = controller.load();
      controller.updateAccess(_access(userId: 'resident-b'));
      expect(controller.isLoading, isFalse);
      expect(controller.items, isEmpty);
      repository.onList = (_) async => [_complaint(id: 'new-session')];
      await controller.load();
      pending.complete([_complaint(id: 'old-session')]);
      await previousLoad;
      expect(controller.items.single.id, 'new-session');
    });

    test(
      'session change ignores a mutation completed by the previous user',
      () async {
        final pending = Completer<Complaint>();
        repository.onCreate = () => pending.future;
        final previousCreate = controller.create('Assunto', 'Descrição');
        controller.updateAccess(_access(userId: 'resident-b'));
        pending.complete(_complaint(id: 'previous-user'));
        expect(await previousCreate, isFalse);
        expect(controller.items, isEmpty);
        expect(controller.isSubmitting, isFalse);
        expect(controller.mutationFailed, isFalse);
      },
    );

    test('an older list response cannot overwrite a new complaint', () async {
      final pending = Completer<List<Complaint>>();
      repository.onList = (_) => pending.future;
      final previousLoad = controller.load();
      expect(await controller.create('Assunto', 'Descrição'), isTrue);
      pending.complete([_complaint(id: 'older-list')]);
      await previousLoad;
      expect(controller.items.single.id, 'created');
      expect(controller.selected?.id, 'created');
    });

    test(
      'expired server session clears data and blocks more requests',
      () async {
        await controller.load();
        repository.onCreate = () =>
            Future.error(const ComplaintSessionExpired());
        expect(await controller.create('Assunto', 'Descrição'), isFalse);
        expect(controller.sessionExpired, isTrue);
        expect(controller.items, isEmpty);
        expect(controller.isSubmitting, isFalse);
        await controller.load();
        expect(await controller.create('Assunto', 'Descrição'), isFalse);
        expect(repository.listCalls, 1);
        expect(repository.createCalls, 1);
      },
    );

    test('same access instance is reevaluated after its expiry', () async {
      final access = _access(
        expiresAt: DateTime.now().add(const Duration(milliseconds: 25)),
      );
      controller.updateAccess(access);
      await controller.load();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      controller.updateAccess(access);
      expect(controller.sessionExpired, isTrue);
      expect(controller.items, isEmpty);
      expect(await controller.create('Assunto', 'Descrição'), isFalse);
      expect(repository.createCalls, 0);
    });

    test(
      'dispose ignores late read completion without notifying listeners',
      () async {
        final pending = Completer<List<Complaint>>();
        final other = ComplaintsController(
          repository: repository,
          access: _access(),
        );
        repository.onList = (_) => pending.future;
        var notifications = 0;
        other.addListener(() => notifications++);
        final load = other.load();
        expect(notifications, 1);
        other.dispose();
        pending.complete([_complaint()]);
        await load;
        expect(notifications, 1);
        expect(other.items, isEmpty);
      },
    );
  });
}

class _FakeRepository implements ComplaintsRepository {
  int listCalls = 0;
  int createCalls = 0;
  int respondCalls = 0;
  int closeCalls = 0;
  ComplaintScope? lastScope;
  String? lastSubject;
  String? lastDescription;
  String? lastMessage;
  Future<List<Complaint>> Function(ComplaintScope scope)? onList;
  Future<Complaint> Function()? onCreate;
  Future<Complaint> Function()? onRespond;
  Complaint _item = _complaint();

  @override
  Future<List<Complaint>> list({required ComplaintScope scope}) {
    listCalls++;
    lastScope = scope;
    return onList?.call(scope) ?? Future.value([_item]);
  }

  @override
  Future<Complaint> create({
    required String subject,
    required String description,
  }) {
    createCalls++;
    lastSubject = subject;
    lastDescription = description;
    return onCreate?.call() ?? Future.value(_complaint(id: 'created'));
  }

  @override
  Future<Complaint> respond({
    required String complaintId,
    required String message,
  }) {
    respondCalls++;
    lastMessage = message;
    if (onRespond != null) return onRespond!();
    _item = _item.copyWith(
      status: ComplaintStatus.answered,
      responses: [
        ..._item.responses,
        ComplaintResponse(message: message, createdAt: DateTime.now()),
      ],
    );
    return Future.value(_item);
  }

  @override
  Future<Complaint> close({required String complaintId}) {
    closeCalls++;
    _item = _item.copyWith(status: ComplaintStatus.closed);
    return Future.value(_item);
  }
}
