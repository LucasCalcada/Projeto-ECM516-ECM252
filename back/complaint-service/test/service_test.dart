import 'package:complaint_service/src/errors.dart';
import 'package:complaint_service/src/models.dart';
import 'package:complaint_service/src/service.dart';
import 'package:test/test.dart';

import 'support/memory_repository.dart';

const resident = AuthContext(
  userId: '11111111-1111-4111-8111-111111111111',
  buildingId: '22222222-2222-4222-8222-222222222222',
  residencyId: '33333333-3333-4333-8333-333333333333',
);
const neighbor = AuthContext(
  userId: '44444444-4444-4444-8444-444444444444',
  buildingId: '22222222-2222-4222-8222-222222222222',
  residencyId: '55555555-5555-4555-8555-555555555555',
);
const admin = AuthContext(
  userId: '66666666-6666-4666-8666-666666666666',
  buildingId: '22222222-2222-4222-8222-222222222222',
  permissions: [manageComplaintsPermission],
);
const otherAdmin = AuthContext(
  userId: '77777777-7777-4777-8777-777777777777',
  buildingId: '88888888-8888-4888-8888-888888888888',
  permissions: [manageComplaintsPermission],
);
const payload = <String, Object?>{
  'title': ' Barulho após as 22h ',
  'category': 'barulho',
  'description': ' Música alta na área comum. ',
};
Matcher fails(int status, [String? code]) => throwsA(
  isA<ApiException>()
      .having((e) => e.statusCode, 'status', status)
      .having((e) => e.code, 'code', code ?? anything),
);

void main() {
  late MemoryComplaintRepository repository;
  late ComplaintService service;
  late DateTime time;
  setUp(() {
    repository = MemoryComplaintRepository();
    time = DateTime.utc(2026, 10, 21);
    service = ComplaintService(
      repository,
      now: () {
        time = time.add(const Duration(seconds: 1));
        return time;
      },
    );
  });

  test('RF01/02 creates identified complaint with initial history', () async {
    final c = await service.create(resident, payload);
    expect(c.title, 'Barulho após as 22h');
    expect(c.description, 'Música alta na área comum.');
    expect(c.buildingId, resident.buildingId);
    expect(c.residentUserId, resident.userId);
    expect(c.status, 'aberta');
    expect(c.closedAt, isNull);
    expect(c.responses, isEmpty);
    expect(c.history.single.previousStatus, isNull);
    expect(c.history.single.authorUserId, resident.userId);
    expect(await service.detail(resident, c.id), c);
  });

  test('RF01 refuses employees, missing, blank and invalid fields', () async {
    await expectLater(service.create(admin, payload), fails(403));
    for (final entry in <Map<String, Object?>>[
      {},
      {...payload, 'title': ' '},
      {...payload, 'title': 12},
      {...payload, 'title': 'Texto\u0000inválido'},
      {...payload, 'description': ''},
      {...payload, 'category': 'inexistente'},
      {...payload, 'title': 'a' * 201},
      {...payload, 'description': 'a' * 10001},
      {...payload, 'residentUserId': neighbor.userId},
      {...payload, 'buildingId': otherAdmin.buildingId},
      {...payload, 'status': 'encerrada'},
    ]) {
      await expectLater(service.create(resident, entry), fails(400));
    }
    expect(repository.complaints, isEmpty);
  });

  test('RF03/04/05/11 isolate residents and buildings', () async {
    final mine = await service.create(resident, payload);
    final theirs = await service.create(neighbor, payload);
    expect((await service.list(resident, {}, mine: true)).map((c) => c.id), [
      mine.id,
    ]);
    await expectLater(service.detail(resident, theirs.id), fails(404));
    await expectLater(service.detail(neighbor, mine.id), fails(404));
    await expectLater(service.list(resident, {}), fails(403));
    expect(await service.list(admin, {}), hasLength(2));
    expect(await service.list(otherAdmin, {}), isEmpty);
    await expectLater(service.detail(otherAdmin, mine.id), fails(404));
    await expectLater(
      service.respond(otherAdmin, mine.id, {'message': 'Resposta'}),
      fails(404),
    );
    await expectLater(
      service.changeStatus(otherAdmin, mine.id, {'status': 'em_analise'}),
      fails(404),
    );
    await expectLater(service.detail(resident, 'wrong-id'), fails(400));
  });

  test('RF06 filters and paginates without broadening visibility', () async {
    final first = await service.create(resident, payload);
    final second = await service.create(resident, {
      ...payload,
      'category': 'limpeza',
    });
    await service.create(neighbor, payload);
    await service.changeStatus(admin, first.id, {'status': 'em_analise'});
    expect(
      (await service.list(resident, {
        'category': 'barulho',
      }, mine: true)).single.id,
      first.id,
    );
    expect(
      (await service.list(admin, {'status': 'em_analise'})).single.id,
      first.id,
    );
    expect(
      (await service.list(resident, {'limit': '1'}, mine: true)).single.id,
      second.id,
    );
    expect(
      (await service.list(resident, {
        'limit': '1',
        'offset': '1',
      }, mine: true)).single.id,
      first.id,
    );
    for (final query in [
      {'limit': '0'},
      {'limit': '101'},
      {'limit': '1.5'},
      {'offset': '-1'},
      {'offset': '999999999999999999999'},
      {'status': 'anything'},
      {'category': ''},
      {'buildingId': otherAdmin.buildingId},
    ]) {
      await expectLater(service.list(resident, query, mine: true), fails(400));
    }
  });

  test('RF07 only administration can append nonempty responses', () async {
    final c = await service.create(resident, payload);
    await expectLater(
      service.respond(resident, c.id, {'message': 'Réplica'}),
      fails(403),
    );
    for (final body in <Map<String, Object?>>[
      {},
      {'message': ' '},
      {'message': 'a' * 5001},
      {'message': 'Resposta', 'authorUserId': resident.userId},
    ]) {
      await expectLater(service.respond(admin, c.id, body), fails(400));
    }
    await service.respond(admin, c.id, {'message': ' Vamos verificar. '});
    final updated = await service.respond(admin, c.id, {
      'message': 'Contato realizado.',
    });
    expect(updated.responses.map((r) => r.message), [
      'Vamos verificar.',
      'Contato realizado.',
    ]);
    expect(updated.responses.first.authorUserId, admin.userId);
    expect(
      updated.responses.last.createdAt.isAfter(
        updated.responses.first.createdAt,
      ),
      isTrue,
    );
    expect(updated.status, 'aberta');
  });

  test('RF08/09/10 forward transitions and closure preserve history', () async {
    final c = await service.create(resident, payload);
    await expectLater(
      service.changeStatus(resident, c.id, {'status': 'em_analise'}),
      fails(403),
    );
    await expectLater(
      service.changeStatus(admin, c.id, {'status': 'encerrada'}),
      fails(409, 'response_required'),
    );
    await service.changeStatus(admin, c.id, {'status': 'em_analise'});
    await expectLater(
      service.changeStatus(admin, c.id, {'status': 'aberta'}),
      fails(409),
    );
    await expectLater(
      service.changeStatus(admin, c.id, {'status': 'em_analise'}),
      fails(409),
    );
    await service.respond(admin, c.id, {
      'message': 'A administração entrou em contato com o responsável.',
    });
    final closed = await service.changeStatus(admin, c.id, {
      'status': 'encerrada',
    });
    expect(closed.history.map((h) => h.status), [
      'aberta',
      'em_analise',
      'encerrada',
    ]);
    expect(closed.history.last.previousStatus, 'em_analise');
    expect(closed.history.last.authorUserId, admin.userId);
    expect(closed.closedAt, closed.updatedAt);
    expect(closed.history.last.createdAt, closed.closedAt);
    await expectLater(
      service.respond(admin, c.id, {'message': 'Outra resposta'}),
      fails(409),
    );
    await expectLater(
      service.changeStatus(admin, c.id, {'status': 'em_analise'}),
      fails(409),
    );
    final persisted = await service.detail(resident, c.id);
    expect(persisted.responses, hasLength(1));
    expect(persisted.history, hasLength(3));
  });

  test('RF09 can close directly from aberta after response', () async {
    final c = await service.create(resident, payload);
    await service.respond(admin, c.id, {
      'message': 'Posicionamento registrado.',
    });
    final closed = await service.changeStatus(admin, c.id, {
      'status': 'encerrada',
    });
    expect(closed.history.map((h) => h.status), ['aberta', 'encerrada']);
    expect((await service.detail(resident, c.id)).status, 'encerrada');
  });
}
