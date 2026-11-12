import 'package:front_flutter/types/complaint_failure.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/helpers/complaints_controller.dart';
import 'package:front_flutter/types/complaint.dart';
import 'package:front_flutter/helpers/complaint_access.dart';
import 'package:front_flutter/helpers/complaints_repository.dart';

Complaint _item(String id, {bool details = true}) => Complaint(
  id: id,
  residencyId: 'residence',
  title: 'Título $id',
  category: 'barulho',
  description: 'Descrição $id',
  createdAt: DateTime.utc(2026, 11, 1),
  status: ComplaintStatus.open,
  hasDetails: details,
);

ComplaintAccess _access({
  String user = 'user',
  bool resident = true,
  List<String> permissions = const [
    '@complaint:create',
    '@complaint:view:residency',
  ],
}) => ComplaintAccess.fromSession(
  userId: user,
  buildingId: 'building',
  permissions: permissions,
  residentAccess: resident,
  residencyId: resident ? 'residence' : null,
  expiresAt: DateTime.utc(2100),
);

class _Repository implements ComplaintsRepository {
  final List<int> offsets = [];
  final List<ComplaintScope> scopes = [];
  final List<String> details = [];
  Future<List<Complaint>> Function(int offset, ComplaintStatus? status)? onList;
  Future<Complaint> Function(String id)? onDetail;
  Future<Complaint> Function()? onRespond;
  int creates = 0;

  @override
  Future<List<Complaint>> list({
    required ComplaintScope scope,
    ComplaintStatus? status,
    String? category,
    int limit = 20,
    int offset = 0,
  }) {
    offsets.add(offset);
    scopes.add(scope);
    return onList?.call(offset, status) ??
        Future.value([
          _item('one', details: false),
          _item('two', details: false),
        ]);
  }

  @override
  Future<Complaint> getDetail(String id) {
    details.add(id);
    return onDetail?.call(id) ?? Future.value(_item(id));
  }

  @override
  Future<Complaint> create({
    required String title,
    required String category,
    required String description,
  }) async {
    creates++;
    return _item('created');
  }

  @override
  Future<Complaint> respond({
    required String complaintId,
    required String message,
  }) => onRespond?.call() ?? Future.value(_item(complaintId));

  @override
  Future<Complaint> changeStatus({
    required String complaintId,
    required ComplaintStatus status,
  }) async => _item(complaintId).copyWith(status: status);

  @override
  Future<Complaint> close({required String complaintId}) =>
      changeStatus(complaintId: complaintId, status: ComplaintStatus.closed);
}

void main() {
  test(
    'raw page size controls offset and exhaustion before deduplication',
    () async {
      final repository = _Repository();
      final controller = ComplaintsController(
        repository: repository,
        access: _access(),
      );
      addTearDown(controller.dispose);
      repository.onList = (offset, _) async {
        if (offset == 0) return List.generate(20, (i) => _item('id-$i'));
        if (offset == 20) {
          return List.generate(20, (i) => _item('id-${i + 10}'));
        }
        return [_item('id-29')];
      };
      await controller.load();
      await controller.load(more: true);
      expect(controller.items.length, 30);
      expect(controller.hasMore, isTrue);
      await controller.load(more: true);
      expect(repository.offsets, [0, 20, 40]);
      expect(controller.items.length, 30);
      expect(controller.hasMore, isFalse);
      await controller.load(more: true);
      expect(repository.offsets.length, 3);
    },
  );

  test(
    'a filter change resets pagination even when its first page fails',
    () async {
      final repository = _Repository();
      final controller = ComplaintsController(
        repository: repository,
        access: _access(),
      );
      addTearDown(controller.dispose);
      repository.onList = (offset, status) async {
        if (status != null) {
          throw const ComplaintException(ComplaintFailure.server);
        }
        return List.generate(20, (i) => _item('id-${offset + i}'));
      };
      await controller.load();
      await controller.load(more: true);
      expect(controller.hasMore, isTrue);
      await controller.setFilters(status: ComplaintStatus.inAnalysis);
      expect(controller.items, isEmpty);
      expect(controller.hasMore, isFalse);
      expect(controller.loadFailure, ComplaintFailure.server);
      expect(repository.offsets, [0, 20, 0]);
      await controller.load(more: true);
      expect(repository.offsets.length, 3);
    },
  );

  test('a stale detail cannot replace the latest selected record', () async {
    final repository = _Repository();
    final controller = ComplaintsController(
      repository: repository,
      access: _access(),
    );
    addTearDown(controller.dispose);
    await controller.load();
    final older = Completer<Complaint>();
    repository.onDetail = (id) =>
        id == 'one' ? older.future : Future.value(_item(id));
    final previous = controller.select('one');
    await controller.select('two');
    older.complete(_item('one'));
    await previous;
    expect(controller.selected?.id, 'two');
    expect(controller.isDetailLoading, isFalse);
  });

  test('session changes discard pending details and protected data', () async {
    final repository = _Repository();
    final controller = ComplaintsController(
      repository: repository,
      access: _access(),
    );
    addTearDown(controller.dispose);
    final pending = Completer<Complaint>();
    repository.onDetail = (_) => pending.future;
    final previous = controller.select('one');
    controller.updateAccess(_access(user: 'other-user'));
    pending.complete(_item('one'));
    await previous;
    expect(controller.items, isEmpty);
    expect(controller.selected, isNull);
    expect(controller.isDetailLoading, isFalse);
  });

  test(
    'creation permission is independent from the currently selected view',
    () async {
      final repository = _Repository();
      final controller = ComplaintsController(
        repository: repository,
        access: _access(permissions: ['@core:admin']),
      );
      addTearDown(controller.dispose);
      expect(controller.access.canCreate, isTrue);
      expect(controller.scope, ComplaintScope.building);
      expect(await controller.create('Título', 'Descrição'), isTrue);
      await controller.setScope(ComplaintScope.mine);
      expect(
        await controller.create('Título', 'Descrição', category: 'barulho'),
        isTrue,
      );
      expect(repository.creates, 2);
    },
  );

  test(
    'residence view permission requires a residence and grants no creation',
    () async {
      final repository = _Repository();
      final controller = ComplaintsController(
        repository: repository,
        access: _access(
          resident: false,
          permissions: ['@complaint:view:residency'],
        ),
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(repository.scopes, isEmpty);
      expect(controller.items, isEmpty);
      expect(await controller.create('Título', 'Descrição'), isFalse);
    },
  );

  test(
    'conflict reconciliation keeps navigation locked until data is current',
    () async {
      final repository = _Repository();
      final controller = ComplaintsController(
        repository: repository,
        access: _access(permissions: ['@core:admin']),
      );
      addTearDown(controller.dispose);
      await controller.load();
      await controller.select('one');
      final refresh = Completer<List<Complaint>>();
      repository.onList = (_, _) => refresh.future;
      repository.onRespond = () =>
          Future.error(const ComplaintException(ComplaintFailure.conflict));
      final mutation = controller.respond('Resposta');
      await Future<void>.delayed(Duration.zero);
      expect(controller.isSubmitting, isTrue);
      await controller.select('two');
      expect(controller.selected?.id, 'one');
      refresh.complete([
        _item('one', details: false),
        _item('two', details: false),
      ]);
      expect(await mutation, isFalse);
      expect(controller.mutationFailure, ComplaintFailure.conflict);
      expect(controller.selected?.id, 'one');
      expect(controller.isSubmitting, isFalse);
    },
  );
}
