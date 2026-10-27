import 'dart:convert';

import 'package:complaint_service/src/app.dart';
import 'package:complaint_service/src/models.dart';
import 'package:complaint_service/src/service.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'support/memory_repository.dart';

const _secret = 'complaints-test-secret';
const _resident = '11111111-1111-4111-8111-111111111111';
const _admin = '33333333-3333-4333-8333-333333333333';
const _building = '22222222-2222-4222-8222-222222222222';
const _residency = '44444444-4444-4444-8444-444444444444';
const _body = {
  'title': 'Barulho na piscina',
  'category': 'barulho',
  'description': 'Música alta após o horário permitido.',
};

String _token({bool admin = false, String building = _building}) => JWT({
  'tokenKind': 'user',
  'userId': admin ? _admin : _resident,
  'buildingId': building,
  'residencyId': admin ? null : _residency,
  'permissions': admin ? [manageComplaintsPermission] : <String>[],
}).sign(SecretKey(_secret), expiresIn: const Duration(hours: 1));

Future<dynamic> _json(Response response) async =>
    jsonDecode(await response.readAsString());

class _UnhealthyRepository extends MemoryComplaintRepository {
  @override
  Future<void> health() async =>
      throw StateError('SQL credentials: secret-password');
}

class _FailingRepository extends MemoryComplaintRepository {
  @override
  Future<void> create(Complaint complaint) async =>
      throw StateError('SQL insert failed with secret-password');
}

void main() {
  late Handler app;
  late MemoryComplaintRepository repository;

  setUp(() {
    repository = MemoryComplaintRepository();
    app = createApp(
      service: ComplaintService(repository),
      repository: repository,
      jwtSecret: _secret,
    );
  });

  Future<Response> send(
    String method,
    String path, {
    Object? body,
    bool admin = false,
    String building = _building,
  }) => Future.sync(
    () => app(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        headers: {
          'authorization': 'Bearer ${_token(admin: admin, building: building)}',
          if (body != null) 'content-type': 'application/json',
        },
        body: body == null ? null : jsonEncode(body),
      ),
    ),
  );

  test('supports the full resident-to-administration lifecycle', () async {
    final created = await send('POST', '/complaints', body: _body);
    expect(created.statusCode, 201);
    final complaint = await _json(created) as Map<String, dynamic>;
    final id = complaint['id'] as String;
    expect(complaint['residentUserId'], _resident);
    expect(complaint['buildingId'], _building);
    expect(complaint['status'], 'aberta');

    final mine = await send(
      'GET',
      '/complaints/mine?status=aberta&category=barulho',
    );
    expect(mine.statusCode, 200);
    expect((await _json(mine) as List).single['id'], id);
    final all = await send('GET', '/complaints', admin: true);
    expect(all.statusCode, 200);
    expect((await _json(all) as List).length, 1);

    final analyzing = await send(
      'PATCH',
      '/complaints/$id/status',
      admin: true,
      body: {'status': 'em_analise'},
    );
    expect(analyzing.statusCode, 200);
    expect((await _json(analyzing))['status'], 'em_analise');
    final responded = await send(
      'POST',
      '/complaints/$id/responses',
      admin: true,
      body: {'message': 'A administração irá reforçar os horários.'},
    );
    expect(responded.statusCode, 201);
    expect(
      (await _json(responded))['responses'].single['authorUserId'],
      _admin,
    );
    final closed = await send(
      'PATCH',
      '/complaints/$id/status',
      admin: true,
      body: {'status': 'encerrada'},
    );
    expect(closed.statusCode, 200);
    expect((await _json(closed))['closedAt'], isNotNull);
    final details = await send('GET', '/complaints/$id');
    expect(details.statusCode, 200);
    final detailBody = await _json(details);
    expect(detailBody['responses'].length, 1);
    expect(detailBody['history'].length, 3);
    final afterClose = await send(
      'POST',
      '/complaints/$id/responses',
      admin: true,
      body: {'message': 'Tentativa após encerramento'},
    );
    expect(afterClose.statusCode, 409);
  });

  test(
    'denies unauthenticated, resident-admin and cross-building access',
    () async {
      final unauthenticated = await app(
        Request('GET', Uri.parse('http://localhost/complaints/mine')),
      );
      expect(unauthenticated.statusCode, 401);
      expect((await _json(unauthenticated))['error']['code'], 'unauthorized');
      expect((await send('GET', '/complaints')).statusCode, 403);
      final created = await send('POST', '/complaints', body: _body);
      final id = (await _json(created))['id'];
      expect(
        (await send(
          'POST',
          '/complaints/$id/responses',
          body: {'message': 'Não autorizado'},
        )).statusCode,
        403,
      );
      final otherBuilding = await send(
        'GET',
        '/complaints/$id',
        admin: true,
        building: '55555555-5555-4555-8555-555555555555',
      );
      expect(otherBuilding.statusCode, 404);
    },
  );

  test('validates JSON objects and content type', () async {
    final array = await send('POST', '/complaints', body: [1, 2]);
    expect(array.statusCode, 400);
    expect((await _json(array))['error']['code'], 'invalid_json');
    for (final invalidBody in ['{', 'null', '"string"']) {
      final response = await app(
        Request(
          'POST',
          Uri.parse('http://localhost/complaints'),
          headers: {
            'authorization': _token(),
            'content-type': 'application/json',
          },
          body: invalidBody,
        ),
      );
      expect(response.statusCode, 400);
    }
    final text = await app(
      Request(
        'POST',
        Uri.parse('http://localhost/complaints'),
        headers: {'authorization': _token(), 'content-type': 'text/plain'},
        body: '{}',
      ),
    );
    expect(text.statusCode, 415);
  });

  test(
    'bounds streaming body size without relying on content-length',
    () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost/complaints'),
        headers: {
          'authorization': _token(),
          'content-type': 'application/json',
        },
        body: Stream<List<int>>.fromIterable([
          List<int>.filled(32768, 32),
          List<int>.filled(32769, 32),
        ]),
      );
      final response = await app(request);
      expect(response.statusCode, 413);
      expect((await _json(response))['error']['code'], 'payload_too_large');
      expect(repository.complaints, isEmpty);
    },
  );

  test('adds CORS headers to preflight and errors', () async {
    final options = await app(
      Request(
        'OPTIONS',
        Uri.parse('http://localhost/complaints'),
        headers: {
          'origin': 'http://localhost:3000',
          'access-control-request-method': 'POST',
        },
      ),
    );
    expect(options.statusCode, 204);
    expect(options.headers['access-control-allow-origin'], '*');
    expect(
      options.headers['access-control-allow-headers'],
      contains('Authorization'),
    );
    final unauthorized = await app(
      Request('GET', Uri.parse('http://localhost/complaints')),
    );
    expect(unauthorized.headers['access-control-allow-origin'], '*');
    expect(unauthorized.mimeType, 'application/json');
    final missing = await send('GET', '/not-found');
    expect(missing.statusCode, 404);
    expect((await _json(missing))['error']['code'], 'not_found');
  });

  test(
    'checks database health without authentication and hides internals',
    () async {
      final healthy = await app(
        Request('GET', Uri.parse('http://localhost/health')),
      );
      expect(healthy.statusCode, 200);
      expect(await _json(healthy), {'status': 'ok'});
      final unhealthyRepository = _UnhealthyRepository();
      final unhealthyApp = createApp(
        service: ComplaintService(unhealthyRepository),
        repository: unhealthyRepository,
        jwtSecret: _secret,
      );
      final unhealthy = await unhealthyApp(
        Request('GET', Uri.parse('http://localhost/health')),
      );
      expect(unhealthy.statusCode, 503);
      final text = await unhealthy.readAsString();
      expect(text, isNot(contains('secret-password')));
      expect(jsonDecode(text)['error']['code'], 'service_unavailable');
      expect(unhealthy.headers['access-control-allow-origin'], '*');
    },
  );

  test(
    'returns a generic JSON error on unexpected repository failures',
    () async {
      final failingRepository = _FailingRepository();
      final failingApp = createApp(
        service: ComplaintService(failingRepository),
        repository: failingRepository,
        jwtSecret: _secret,
      );
      final response = await failingApp(
        Request(
          'POST',
          Uri.parse('http://localhost/complaints'),
          headers: {
            'authorization': _token(),
            'content-type': 'application/json',
          },
          body: jsonEncode(_body),
        ),
      );
      expect(response.statusCode, 500);
      final text = await response.readAsString();
      expect(text, isNot(contains('secret-password')));
      expect(jsonDecode(text)['error']['code'], 'internal_error');
      expect(response.headers['access-control-allow-origin'], '*');
    },
  );
}
