import 'dart:io';

import 'package:complaint_service/src/config.dart';
import 'package:complaint_service/src/database.dart';
import 'package:complaint_service/src/errors.dart';
import 'package:complaint_service/src/models.dart';
import 'package:complaint_service/src/postgres_repository.dart';
import 'package:complaint_service/src/service.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  final databaseUrl = Platform.environment['TEST_DATABASE_URL'];
  const uuid = Uuid();
  late Pool<void> pool;
  late PostgresComplaintRepository repository;
  late ComplaintService service;
  late AuthContext resident;
  late AuthContext administrator;
  late String otherBuildingId;

  group(
    'PostgreSQL complaint persistence',
    () {
      setUpAll(() async {
        pool = createDatabasePool(
          AppConfig.fromEnvironment({
            'DATABASE_URL': databaseUrl!,
            'DATABASE_SSL_MODE':
                Platform.environment['TEST_DATABASE_SSL_MODE'] ?? 'disable',
          }),
        );
        final migrations =
            Directory('migrations')
                .listSync()
                .whereType<File>()
                .where((file) => file.path.endsWith('.sql'))
                .toList()
              ..sort((a, b) => a.path.compareTo(b.path));
        // Applying twice verifies that startup migration is safely repeatable.
        for (var i = 0; i < 2; i++) {
          await pool.runTx((session) async {
            for (final file in migrations) {
              await session.execute(
                await file.readAsString(),
                queryMode: QueryMode.simple,
              );
            }
          });
        }
        repository = PostgresComplaintRepository(pool);
        service = ComplaintService(repository);
      });

      setUp(() {
        resident = AuthContext(
          userId: uuid.v4(),
          buildingId: uuid.v4(),
          residencyId: uuid.v4(),
          permissions: const [
            createComplaintPermission,
            viewResidencyComplaintsPermission,
          ],
        );
        administrator = AuthContext(
          userId: uuid.v4(),
          buildingId: resident.buildingId,
          permissions: const [
            viewBuildingComplaintsPermission,
            updateComplaintStatusPermission,
            respondBuildingComplaintPermission,
          ],
        );
        otherBuildingId = uuid.v4();
      });

      tearDown(() async {
        // Clean up only the random buildings belonging to this test run.
        await pool.runTx((session) async {
          final parameters = {
            'buildingId': resident.buildingId,
            'otherBuildingId': otherBuildingId,
          };
          const scope = '''
          SELECT id FROM complaints
          WHERE building_id IN (@buildingId, @otherBuildingId)
        ''';
          await session.execute(
            Sql.named(
              'DELETE FROM complaint_responses WHERE complaint_id IN ($scope)',
            ),
            parameters: parameters,
          );
          await session.execute(
            Sql.named(
              'DELETE FROM complaint_status_history WHERE complaint_id IN ($scope)',
            ),
            parameters: parameters,
          );
          await session.execute(
            Sql.named('DELETE FROM complaints WHERE id IN ($scope)'),
            parameters: parameters,
          );
        });
      });

      tearDownAll(() => repository.close());

      test(
        'shares a residence across users and persists reply authority',
        () async {
          final created = await service.create(resident, {
            'title': 'Residencia compartilhada',
            'category': 'outros',
            'description': 'Registro para os moradores da mesma residencia.',
          });
          final coResident = AuthContext(
            userId: uuid.v4(),
            buildingId: resident.buildingId,
            residencyId: resident.residencyId,
            permissions: const [
              viewResidencyComplaintsPermission,
              respondResidencyComplaintPermission,
            ],
          );
          final neighbor = AuthContext(
            userId: uuid.v4(),
            buildingId: resident.buildingId,
            residencyId: uuid.v4(),
            permissions: const [
              viewResidencyComplaintsPermission,
              respondResidencyComplaintPermission,
            ],
          );
          expect(
            (await service.list(coResident, {}, mine: true)).single.id,
            created.id,
          );
          expect(await service.list(neighbor, {}, mine: true), isEmpty);
          await expectLater(
            service.detail(neighbor, created.id),
            throwsA(
              isA<ApiException>().having((e) => e.statusCode, 'status', 404),
            ),
          );
          await service.respond(coResident, created.id, {
            'message': 'Complemento de outro morador',
          });
          await service.respond(administrator, created.id, {
            'message': 'Resposta da administracao',
          });
          final loaded = (await repository.find(
            created.id,
            resident.buildingId,
          ))!;
          expect(loaded.residencyId, resident.residencyId);
          expect(loaded.responses.map((reply) => reply.isAdministrative), [
            false,
            true,
          ]);
          await service.changeStatus(administrator, created.id, {
            'status': 'encerrada',
          });
        },
      );

      test(
        'residence stays attached to the record when its author moves',
        () async {
          final created = await service.create(resident, {
            'title': 'Residencia original',
            'category': 'outros',
            'description': 'O vinculo do registro nao acompanha a mudanca de residencia do autor.',
          });
          final moved = AuthContext(
            userId: resident.userId,
            buildingId: resident.buildingId,
            residencyId: uuid.v4(),
            permissions: const [viewResidencyComplaintsPermission],
          );
          final remaining = AuthContext(
            userId: uuid.v4(),
            buildingId: resident.buildingId,
            residencyId: resident.residencyId,
            permissions: const [viewResidencyComplaintsPermission],
          );
          expect(await service.list(moved, {}, mine: true), isEmpty);
          expect(
            (await service.list(remaining, {}, mine: true)).single.id,
            created.id,
          );
          await expectLater(
            service.detail(moved, created.id),
            throwsA(
              isA<ApiException>().having((e) => e.statusCode, 'status', 404),
            ),
          );
        },
      );

      test(
        'persists initial history and keeps building scope private',
        () async {
          final created = await service.create(resident, {
            'title': 'Barulho na área comum',
            'category': 'barulho',
            'description': 'Música alta após o horário permitido.',
          });
          final loaded = await repository.find(created.id, resident.buildingId);
          expect(loaded!.toJson(), created.toJson());
          expect(loaded.history.single.previousStatus, isNull);
          expect(await repository.find(created.id, otherBuildingId), isNull);
          await expectLater(
            repository.update(
              created.id,
              otherBuildingId,
              (current) => current,
            ),
            throwsA(same(ApiException.notFound)),
          );
          await repository.health();
        },
      );

      test('lists with stable pagination and combined filters', () async {
        final sameTime = DateTime.utc(2026, 10, 21, 12);
        final fixedService = ComplaintService(repository, now: () => sameTime);
        final created = <Complaint>[];
        for (var i = 0; i < 3; i++) {
          created.add(
            await fixedService.create(resident, {
              'title': 'Reclamação $i',
              'category': 'limpeza',
              'description': 'Limpeza pendente no corredor.',
            }),
          );
        }
        await fixedService.create(
          AuthContext(
            userId: uuid.v4(),
            buildingId: otherBuildingId,
            residencyId: uuid.v4(),
            permissions: const [createComplaintPermission],
          ),
          {
            'title': 'Outro condomínio',
            'category': 'limpeza',
            'description': 'Teste',
          },
        );
        final expectedIds = created.map((entry) => entry.id).toList()
          ..sort((a, b) => b.compareTo(a));
        final firstPage = await repository.list(
          ComplaintQuery(
            buildingId: resident.buildingId,
            residentUserId: resident.userId,
            status: 'aberta',
            category: 'limpeza',
            limit: 2,
          ),
        );
        final secondPage = await repository.list(
          ComplaintQuery(
            buildingId: resident.buildingId,
            residentUserId: resident.userId,
            status: 'aberta',
            category: 'limpeza',
            limit: 2,
            offset: 2,
          ),
        );
        expect(
          [...firstPage, ...secondPage].map((entry) => entry.id),
          expectedIds,
        );
        expect(
          await repository.list(
            ComplaintQuery(
              buildingId: resident.buildingId,
              residentUserId: uuid.v4(),
            ),
          ),
          isEmpty,
        );
      });

      test(
        'rolls back the status change if an appended record fails',
        () async {
          final complaint = await service.create(resident, {
            'title': 'Corredor sujo',
            'category': 'limpeza',
            'description': 'O corredor precisa de limpeza.',
          });
          final answered = await service.respond(administrator, complaint.id, {
            'message': 'A equipe foi acionada.',
          });
          await expectLater(
            repository.update(complaint.id, resident.buildingId, (current) {
              final now = DateTime.now().toUtc();
              return current.copyWith(
                status: 'em_analise',
                updatedAt: now,
                // Duplicate primary key makes the append fail after UPDATE.
                responses: [...current.responses, current.responses.single],
                history: [
                  ...current.history,
                  StatusChange(
                    id: uuid.v4(),
                    previousStatus: 'aberta',
                    status: 'em_analise',
                    authorUserId: administrator.userId,
                    createdAt: now,
                  ),
                ],
              );
            }),
            throwsA(isA<ServerException>()),
          );
          final persisted = await repository.find(
            complaint.id,
            resident.buildingId,
          );
          expect(persisted!.toJson(), answered.toJson());
        },
      );

      test(
        'concurrent closure cannot append duplicate final history',
        () async {
          final complaint = await service.create(resident, {
            'title': 'Ruído na garagem',
            'category': 'barulho',
            'description': 'Ruído excessivo à noite.',
          });
          await service.respond(administrator, complaint.id, {
            'message': 'Os responsáveis foram orientados.',
          });
          Future<Object> close() async {
            try {
              return await service.changeStatus(administrator, complaint.id, {
                'status': 'encerrada',
              });
            } on ApiException catch (error) {
              return error;
            }
          }

          final outcomes = await Future.wait([close(), close()]);
          expect(outcomes.whereType<Complaint>(), hasLength(1));
          expect(
            outcomes.whereType<ApiException>().single.code,
            'complaint_closed',
          );
          final persisted = await repository.find(
            complaint.id,
            resident.buildingId,
          );
          expect(persisted!.status, 'encerrada');
          expect(persisted.closedAt, isNotNull);
          expect(persisted.responses, hasLength(1));
          expect(persisted.history.map((entry) => entry.status), [
            'aberta',
            'encerrada',
          ]);
        },
      );
    },
    skip: databaseUrl == null
        ? 'Set TEST_DATABASE_URL to run database tests.'
        : false,
  );
}
