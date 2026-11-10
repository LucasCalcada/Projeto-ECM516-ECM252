import 'package:complaint_service/src/errors.dart';
import 'package:complaint_service/src/models.dart';
import 'package:complaint_service/src/service.dart';
import 'package:test/test.dart';

import 'support/memory_repository.dart';

const building = '11111111-1111-4111-8111-111111111111';
const residence = '22222222-2222-4222-8222-222222222222';
const otherResidence = '33333333-3333-4333-8333-333333333333';
const author = '44444444-4444-4444-8444-444444444444';
const coResident = '55555555-5555-4555-8555-555555555555';
const otherBuilding = '66666666-6666-4666-8666-666666666666';
const body = {
  'title': 'Relato',
  'category': 'outros',
  'description': 'Situacao a acompanhar.',
};

AuthContext actor(
  List<String> permissions, {
  String user = author,
  String? residency = residence,
  String buildingId = building,
}) => AuthContext(
  userId: user,
  buildingId: buildingId,
  residencyId: residency,
  permissions: permissions,
);
Matcher denied(int status) => throwsA(
  isA<ApiException>().having((error) => error.statusCode, 'status', status),
);

void main() {
  late ComplaintService service;
  late Complaint saved;
  setUp(() async {
    service = ComplaintService(MemoryComplaintRepository());
    saved = await service.create(actor([createComplaintPermission]), body);
  });

  test('no permission grants no operation, including the author', () async {
    final user = actor([]);
    await expectLater(service.create(user, body), denied(403));
    await expectLater(service.list(user, {}, mine: true), denied(403));
    await expectLater(service.list(user, {}), denied(403));
    await expectLater(service.detail(user, saved.id), denied(403));
    await expectLater(
      service.respond(user, saved.id, {'message': 'Texto'}),
      denied(403),
    );
    await expectLater(
      service.changeStatus(user, saved.id, {'status': 'em_analise'}),
      denied(403),
    );
  });

  test(
    'create requires its own permission and building, not a residence',
    () async {
      final created = await service.create(
        actor([createComplaintPermission], residency: null),
        body,
      );
      expect(created.buildingId, building);
      expect(created.residencyId, isNull);
      expect(saved.residencyId, residence);
      await expectLater(
        service.create(
          actor([createComplaintPermission], buildingId: ''),
          body,
        ),
        denied(401),
      );
      for (final field in ['buildingId', 'residencyId', 'residentUserId']) {
        await expectLater(
          service.create(actor([createComplaintPermission]), {
            ...body,
            field: otherResidence,
          }),
          denied(400),
        );
      }
      await expectLater(
        service.list(actor([createComplaintPermission]), {}, mine: true),
        denied(403),
      );
    },
  );

  test(
    'residence viewers share records across authors, never across residences',
    () async {
      final sameResidence = await service.create(
        actor([createComplaintPermission], user: coResident),
        body,
      );
      final neighbor = await service.create(
        actor([createComplaintPermission], residency: otherResidence),
        body,
      );
      final viewer = actor([
        viewResidencyComplaintsPermission,
      ], user: coResident);
      expect(
        (await service.list(viewer, {}, mine: true)).map((item) => item.id),
        containsAll([saved.id, sameResidence.id]),
      );
      expect(await service.detail(viewer, saved.id), saved);
      await expectLater(service.detail(viewer, neighbor.id), denied(404));
      await expectLater(service.list(viewer, {}), denied(403));
      await expectLater(service.create(viewer, body), denied(403));
      await expectLater(
        service.respond(viewer, saved.id, {'message': 'Texto'}),
        denied(403),
      );
      await expectLater(
        service.changeStatus(viewer, saved.id, {'status': 'em_analise'}),
        denied(403),
      );
      await expectLater(
        service.list(
          actor([viewResidencyComplaintsPermission], residency: null),
          {},
          mine: true,
        ),
        denied(403),
      );
    },
  );

  test(
    'building view never grants mutation permissions or another building',
    () async {
      await service.create(
        actor([createComplaintPermission], residency: otherResidence),
        body,
      );
      final viewer = actor([viewBuildingComplaintsPermission], residency: null);
      expect(await service.list(viewer, {}), hasLength(2));
      expect(await service.detail(viewer, saved.id), saved);
      await expectLater(service.create(viewer, body), denied(403));
      await expectLater(
        service.respond(viewer, saved.id, {'message': 'Texto'}),
        denied(403),
      );
      await expectLater(
        service.changeStatus(viewer, saved.id, {'status': 'em_analise'}),
        denied(403),
      );
      await expectLater(
        service.detail(
          actor([viewBuildingComplaintsPermission], buildingId: otherBuilding),
          saved.id,
        ),
        denied(404),
      );
    },
  );

  test(
    'residence replies allow a co-resident, never a neighbor or administration',
    () async {
      final reply = actor([
        respondResidencyComplaintPermission,
      ], user: coResident);
      final updated = await service.respond(reply, saved.id, {
        'message': 'Complemento do morador',
      });
      expect(updated.responses.single.authorUserId, coResident);
      expect(updated.responses.single.isAdministrative, isFalse);
      expect(updated.status, 'aberta');
      await expectLater(
        service.respond(
          actor([
            respondResidencyComplaintPermission,
          ], residency: otherResidence),
          saved.id,
          {'message': 'Vizinho'},
        ),
        denied(404),
      );
      await expectLater(
        service.respond(
          actor([respondResidencyComplaintPermission], residency: null),
          saved.id,
          {'message': 'Sem residencia'},
        ),
        denied(403),
      );
      await expectLater(
        service.changeStatus(reply, saved.id, {'status': 'em_analise'}),
        denied(403),
      );
      await expectLater(service.detail(reply, saved.id), denied(403));
    },
  );

  test(
    'building reply is independent from building view and status update',
    () async {
      final reply = actor([
        respondBuildingComplaintPermission,
      ], residency: null);
      final updated = await service.respond(reply, saved.id, {
        'message': 'Resposta administrativa',
      });
      expect(updated.responses.single.isAdministrative, isTrue);
      await expectLater(service.list(reply, {}), denied(403));
      await expectLater(
        service.changeStatus(reply, saved.id, {'status': 'em_analise'}),
        denied(403),
      );
      await expectLater(
        service.respond(
          actor([
            respondBuildingComplaintPermission,
          ], buildingId: otherBuilding),
          saved.id,
          {'message': 'Outro predio'},
        ),
        denied(404),
      );
    },
  );

  test('status permission does not grant replies and closure needs administrative reply', () async {
    final status = actor([updateComplaintStatusPermission], residency: null);
    await service.respond(
      actor([respondResidencyComplaintPermission], user: coResident),
      saved.id,
      {'message': 'Complemento'},
    );
    await service.changeStatus(status, saved.id, {'status': 'em_analise'});
    await expectLater(
      service.changeStatus(status, saved.id, {'status': 'encerrada'}),
      denied(409),
    );
    await expectLater(
      service.respond(status, saved.id, {'message': 'Sem permissao'}),
      denied(403),
    );
    await expectLater(service.list(status, {}), denied(403));
    await service.respond(
      actor([respondBuildingComplaintPermission]),
      saved.id,
      {'message': 'Posicionamento'},
    );
    final closed = await service.changeStatus(status, saved.id, {
      'status': 'encerrada',
    });
    expect(closed.status, 'encerrada');
  });

  test(
    'core administrator grants all actions inside the token building',
    () async {
      final admin = actor(['@core:admin'], residency: null);
      expect(await service.list(admin, {}), hasLength(1));
      await service.create(admin, body);
      await service.respond(admin, saved.id, {'message': 'Resposta'});
      await service.changeStatus(admin, saved.id, {'status': 'encerrada'});
      await expectLater(
        service.detail(
          actor(['@core:admin'], buildingId: otherBuilding),
          saved.id,
        ),
        denied(404),
      );
      await expectLater(
        service.changeStatus(
          actor(['@core:admin'], buildingId: otherBuilding),
          saved.id,
          {'status': 'em_analise'},
        ),
        denied(404),
      );
    },
  );

  test('legacy manage does not silently restore the old broad grant', () async {
    final legacy = actor(['@complaint:manage']);
    await expectLater(service.list(legacy, {}), denied(403));
    await expectLater(service.create(legacy, body), denied(403));
    await expectLater(
      service.respond(legacy, saved.id, {'message': 'Texto'}),
      denied(403),
    );
    await expectLater(
      service.changeStatus(legacy, saved.id, {'status': 'em_analise'}),
      denied(403),
    );
  });

  test(
    'unassigned historical records stay limited to building viewers',
    () async {
      final unassigned = await service.create(
        actor([createComplaintPermission], residency: null),
        body,
      );
      expect(
        (await service.list(
          actor([viewResidencyComplaintsPermission]),
          {},
          mine: true,
        )).map((item) => item.id),
        isNot(contains(unassigned.id)),
      );
      await expectLater(
        service.detail(
          actor([viewResidencyComplaintsPermission]),
          unassigned.id,
        ),
        denied(404),
      );
      expect(
        await service.detail(
          actor([viewBuildingComplaintsPermission]),
          unassigned.id,
        ),
        unassigned,
      );
    },
  );
}
