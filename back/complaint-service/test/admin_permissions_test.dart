import 'dart:convert';

import 'package:complaint_service/src/app.dart';
import 'package:complaint_service/src/service.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'support/memory_repository.dart';

const _secret = 'admin-permissions-regression-secret';
const _resident = '11111111-1111-4111-8111-111111111111';
const _administrator = '22222222-2222-4222-8222-222222222222';
const _building = '33333333-3333-4333-8333-333333333333';
const _otherBuilding = '44444444-4444-4444-8444-444444444444';
const _residency = '55555555-5555-4555-8555-555555555555';
const _complaint = {
  'title': 'Iluminação na garagem',
  'category': 'areas_comuns',
  'description': 'As lâmpadas do corredor precisam de manutenção.',
};

String _token({String? permission, String building = _building}) => JWT({
  'tokenKind': 'user',
  'userId': permission == null ? _resident : _administrator,
  'buildingId': building,
  if (permission == null) 'residencyId': _residency,
  'permissions': [?permission],
}).sign(SecretKey(_secret), expiresIn: const Duration(hours: 1));

Future<dynamic> _json(Response response) async =>
    jsonDecode(await response.readAsString());

void main() {
  late Handler app;

  setUp(() {
    final repository = MemoryComplaintRepository();
    app = createApp(
      service: ComplaintService(repository),
      repository: repository,
      jwtSecret: _secret,
    );
  });

  Future<Response> send(
    String method,
    String path, {
    String? permission,
    String building = _building,
    Object? body,
  }) => Future.sync(
    () => app(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        headers: {
          'authorization':
              'Bearer ${_token(permission: permission, building: building)}',
          if (body != null) 'content-type': 'application/json',
        },
        body: body == null ? null : jsonEncode(body),
      ),
    ),
  );

  for (final permission in ['@core:admin', '@complaint:manage']) {
    group('$permission management', () {
      test('supports the complete administrative lifecycle', () async {
        final created = await send('POST', '/complaints', body: _complaint);
        expect(created.statusCode, 201);
        final id = (await _json(created))['id'] as String;

        final listed = await send('GET', '/complaints', permission: permission);
        expect(listed.statusCode, 200);
        final summaries = await _json(listed) as List;
        expect(summaries.single['id'], id);
        expect(summaries.single.containsKey('responses'), isFalse);
        expect(summaries.single.containsKey('history'), isFalse);

        final prematureClose = await send(
          'PATCH',
          '/complaints/$id/status',
          permission: permission,
          body: {'status': 'encerrada'},
        );
        expect(prematureClose.statusCode, 409);
        expect(
          (await _json(prematureClose))['error']['code'],
          'response_required',
        );

        final response = await send(
          'POST',
          '/complaints/$id/responses',
          permission: permission,
          body: {'message': 'A equipe realizará a manutenção.'},
        );
        expect(response.statusCode, 201);
        final responded = await _json(response);
        expect(responded['status'], 'aberta');
        expect(responded['responses'].length, 1);

        final analyzing = await send(
          'PATCH',
          '/complaints/$id/status',
          permission: permission,
          body: {'status': 'em_analise'},
        );
        expect(analyzing.statusCode, 200);
        expect((await _json(analyzing))['status'], 'em_analise');

        final closed = await send(
          'PATCH',
          '/complaints/$id/status',
          permission: permission,
          body: {'status': 'encerrada'},
        );
        expect(closed.statusCode, 200);
        final closedBody = await _json(closed);
        expect(closedBody['status'], 'encerrada');
        expect(closedBody['closedAt'], isNotNull);

        final detail = await send(
          'GET',
          '/complaints/$id',
          permission: permission,
        );
        expect(detail.statusCode, 200);
        final detailBody = await _json(detail);
        expect(detailBody['responses'].length, 1);
        expect(detailBody['history'].length, 3);

        final afterClose = await send(
          'POST',
          '/complaints/$id/responses',
          permission: permission,
          body: {'message': 'Resposta posterior ao encerramento'},
        );
        expect(afterClose.statusCode, 409);
      });

      test('remains isolated to the administrator building', () async {
        final created = await send('POST', '/complaints', body: _complaint);
        final id = (await _json(created))['id'] as String;

        final list = await send(
          'GET',
          '/complaints',
          permission: permission,
          building: _otherBuilding,
        );
        expect(list.statusCode, 200);
        expect(await _json(list), isEmpty);

        for (final operation in [
          ('GET', '/complaints/$id', null),
          (
            'POST',
            '/complaints/$id/responses',
            {'message': 'Tentativa externa'},
          ),
          ('PATCH', '/complaints/$id/status', {'status': 'em_analise'}),
        ]) {
          final response = await send(
            operation.$1,
            operation.$2,
            permission: permission,
            building: _otherBuilding,
            body: operation.$3,
          );
          expect(response.statusCode, 404);
        }
      });
    });
  }

  test('an unrelated permission does not grant administration', () async {
    final created = await send('POST', '/complaints', body: _complaint);
    final id = (await _json(created))['id'] as String;
    const permission = '@core:user:manage';
    expect(
      (await send('GET', '/complaints', permission: permission)).statusCode,
      403,
    );
    expect(
      (await send(
        'POST',
        '/complaints/$id/responses',
        permission: permission,
        body: {'message': 'Tentativa sem permissão'},
      )).statusCode,
      403,
    );
  });
}
