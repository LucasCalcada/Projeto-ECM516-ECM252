import 'package:front_flutter/types/complaint_failure.dart';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/helpers/http_complaints_repository.dart';
import 'package:front_flutter/types/complaint.dart';
import 'package:front_flutter/helpers/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, Object?> _dto({bool details = true, String status = 'aberta'}) => {
  'id': 'complaint-id',
  'buildingId': 'internal-building',
  'residentUserId': 'internal-resident',
  'title': 'Lâmpada da garagem',
  'category': 'areas_comuns',
  'description': 'O corredor está sem iluminação.',
  'status': status,
  'createdAt': '2026-11-01T12:00:00.000Z',
  'updatedAt': '2026-11-01T12:01:00.000Z',
  'closedAt': null,
  if (details)
    'responses': [
      {
        'id': 'response-id',
        'authorUserId': 'internal-administrator',
        'message': 'Manutenção agendada.',
        'createdAt': '2026-11-01T12:01:00.000Z',
      },
    ],
  if (details)
    'history': [
      {
        'id': 'history-id',
        'previousStatus': null,
        'status': 'aberta',
        'authorUserId': 'internal-resident',
        'createdAt': '2026-11-01T12:00:00.000Z',
      },
    ],
};

HttpComplaintsRepository _repository(
  Future<http.Response> Function(http.Request) handler,
) => HttpComplaintsRepository(
  ApiClient(client: MockClient(handler), baseUrl: 'http://api.test:8007/'),
  token: 'selected-user-token',
);

http.Response _json(Object? value, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(value)),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  test(
    'list uses personal endpoint, whitelisted filters and user Bearer',
    () async {
      final repository = _repository((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/complaints/residency');
        expect(request.headers['Authorization'], 'Bearer selected-user-token');
        expect(request.url.queryParameters, {
          'status': 'em_analise',
          'category': 'barulho',
          'limit': '20',
          'offset': '40',
        });
        return _json([_dto(details: false)]);
      });
      final result = await repository.list(
        scope: ComplaintScope.mine,
        status: ComplaintStatus.inAnalysis,
        category: 'barulho',
        offset: 40,
      );
      expect(result.single.title, 'Lâmpada da garagem');
      expect(result.single.hasDetails, isFalse);
      expect(result.single.responses, isEmpty);
      expect(result.single.history, isEmpty);
    },
  );

  test(
    'building scope omits absent filters and does not invent total',
    () async {
      final repository = _repository((request) async {
        expect(request.url.path, '/complaints');
        expect(request.url.queryParameters, {'limit': '20', 'offset': '0'});
        return _json([]);
      });
      expect(await repository.list(scope: ComplaintScope.building), isEmpty);
    },
  );

  test(
    'detail maps responses, history, UTC dates and unknown status safely',
    () async {
      final repository = _repository((request) async {
        expect(request.url.path, '/complaints/complaint-id');
        return _json(_dto(status: 'future_status'));
      });
      final result = await repository.getDetail('complaint-id');
      expect(result.hasDetails, isTrue);
      expect(result.createdAt.isUtc, isTrue);
      expect(result.status, ComplaintStatus.unknown);
      expect(result.responses.single.message, 'Manutenção agendada.');
      expect(result.history.single.status, ComplaintStatus.open);
    },
  );

  test('create sends only real fields and accepts HTTP 201', () async {
    final repository = _repository((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/complaints');
      expect(request.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(request.body), {
        'title': 'Título',
        'category': 'barulho',
        'description': 'Descrição',
      });
      return _json(_dto(), 201);
    });
    final result = await repository.create(
      title: '  Título  ',
      category: 'barulho',
      description: '  Descrição  ',
    );
    expect(result.hasDetails, isTrue);
  });

  test(
    'respond and status are distinct operations with exact payloads',
    () async {
      final requests = <String>[];
      final repository = _repository((request) async {
        requests.add(request.method);
        if (request.method == 'POST') {
          expect(request.url.path, '/complaints/complaint-id/responses');
          expect(jsonDecode(request.body), {'message': 'Resposta'});
          return _json(_dto(), 201);
        }
        expect(request.url.path, '/complaints/complaint-id/status');
        expect(jsonDecode(request.body), {'status': 'em_analise'});
        return _json(_dto(status: 'em_analise'));
      });
      expect(
        (await repository.respond(
          complaintId: 'complaint-id',
          message: '  Resposta  ',
        )).status,
        ComplaintStatus.open,
      );
      expect(
        (await repository.changeStatus(
          complaintId: 'complaint-id',
          status: ComplaintStatus.inAnalysis,
        )).status,
        ComplaintStatus.inAnalysis,
      );
      expect(requests, ['POST', 'PATCH']);
    },
  );

  for (final entry in <int, ComplaintFailure>{
    400: ComplaintFailure.validation,
    403: ComplaintFailure.forbidden,
    404: ComplaintFailure.notFound,
    409: ComplaintFailure.conflict,
    413: ComplaintFailure.validation,
    415: ComplaintFailure.validation,
    500: ComplaintFailure.server,
  }.entries) {
    test(
      'maps HTTP ${entry.key} and preserves structured code without retry',
      () async {
        var calls = 0;
        final repository = _repository((_) async {
          calls++;
          return _json({
            'error': {'code': 'business_code', 'message': 'Mensagem interna'},
          }, entry.key);
        });
        await expectLater(
          repository.respond(complaintId: 'id', message: 'Resposta'),
          throwsA(
            isA<ComplaintException>()
                .having((error) => error.failure, 'failure', entry.value)
                .having((error) => error.code, 'code', 'business_code'),
          ),
        );
        expect(calls, 1);
      },
    );
  }

  test('401 becomes the existing session-expired signal', () async {
    final repository = _repository(
      (_) async => _json({
        'error': {'code': 'unauthorized'},
      }, 401),
    );
    await expectLater(
      repository.list(scope: ComplaintScope.mine),
      throwsA(isA<ComplaintSessionExpired>()),
    );
  });

  test(
    'transport failure is recoverable network failure with no automatic retry',
    () async {
      var calls = 0;
      final repository = _repository((_) async {
        calls++;
        throw http.ClientException('Connection lost');
      });
      await expectLater(
        repository.create(
          title: 'Título',
          category: 'barulho',
          description: 'Descrição',
        ),
        throwsA(
          isA<ComplaintException>().having(
            (error) => error.failure,
            'failure',
            ComplaintFailure.network,
          ),
        ),
      );
      expect(calls, 1);
    },
  );

  test('invalid JSON and a summary used as detail are rejected', () async {
    for (final response in [
      http.Response('invalid json', 200),
      _json(_dto(details: false)),
    ]) {
      final repository = _repository((_) async => response);
      await expectLater(
        repository.getDetail('id'),
        throwsA(
          isA<ComplaintException>().having(
            (error) => error.failure,
            'failure',
            ComplaintFailure.invalidResponse,
          ),
        ),
      );
    }
  });
}
