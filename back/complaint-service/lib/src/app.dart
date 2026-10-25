import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth.dart';
import 'errors.dart';
import 'repository.dart';
import 'service.dart';

const _corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, PATCH, OPTIONS',
  'access-control-allow-headers': 'Authorization, Content-Type',
  'access-control-max-age': '86400',
};
const _maximumBodyBytes = 64 * 1024;

Handler createApp({
  required ComplaintService service,
  required ComplaintRepository repository,
  required String jwtSecret,
}) {
  final router = Router();
  router.get('/health', (Request request) async {
    try {
      await repository.health();
      return _json(200, {'status': 'ok'});
    } catch (_) {
      throw const ApiException(
        503,
        'service_unavailable',
        'Serviço temporariamente indisponível.',
      );
    }
  });
  router.post('/complaints', (Request request) async {
    final actor = authenticate(request.headers['authorization'], jwtSecret);
    final complaint = await service.create(actor, await _readObject(request));
    return _json(201, complaint.toJson());
  });
  router.get('/complaints/mine', (Request request) async {
    final actor = authenticate(request.headers['authorization'], jwtSecret);
    final complaints = await service.list(
      actor,
      request.url.queryParameters,
      mine: true,
    );
    return _json(200, complaints.map((c) => c.toJson(details: false)).toList());
  });
  router.get('/complaints', (Request request) async {
    final actor = authenticate(request.headers['authorization'], jwtSecret);
    final complaints = await service.list(actor, request.url.queryParameters);
    return _json(200, complaints.map((c) => c.toJson(details: false)).toList());
  });
  router.get('/complaints/<id>', (Request request, String id) async {
    final actor = authenticate(request.headers['authorization'], jwtSecret);
    return _json(200, (await service.detail(actor, id)).toJson());
  });
  router.post('/complaints/<id>/responses', (Request request, String id) async {
    final actor = authenticate(request.headers['authorization'], jwtSecret);
    final complaint = await service.respond(
      actor,
      id,
      await _readObject(request),
    );
    return _json(201, complaint.toJson());
  });
  router.patch('/complaints/<id>/status', (Request request, String id) async {
    final actor = authenticate(request.headers['authorization'], jwtSecret);
    final complaint = await service.changeStatus(
      actor,
      id,
      await _readObject(request),
    );
    return _json(200, complaint.toJson());
  });

  return (Request request) async {
    if (request.method == 'OPTIONS') {
      return Response(204, headers: _corsHeaders);
    }
    try {
      final response = await router.call(request);
      if (response.statusCode == 404) {
        return _error(
          const ApiException(404, 'not_found', 'Rota não encontrada.'),
        );
      }
      if (response.statusCode == 405) {
        return _error(
          const ApiException(
            405,
            'method_not_allowed',
            'Método não permitido.',
          ),
        );
      }
      return response.change(headers: _corsHeaders);
    } on ApiException catch (error) {
      return _error(error);
    } catch (_) {
      return _error(
        const ApiException(
          500,
          'internal_error',
          'Não foi possível processar a solicitação.',
        ),
      );
    }
  };
}

Future<Map<String, Object?>> _readObject(Request request) async {
  String? contentType;
  int? contentLength;
  try {
    contentType = request.mimeType;
    contentLength = request.contentLength;
  } on FormatException {
    throw const ApiException(
      400,
      'invalid_request',
      'Cabeçalhos de conteúdo inválidos.',
    );
  }
  if (contentType != 'application/json') {
    throw const ApiException(
      415,
      'unsupported_media_type',
      'Envie o conteúdo como application/json.',
    );
  }
  if (contentLength != null && contentLength > _maximumBodyBytes) {
    throw const ApiException(
      413,
      'payload_too_large',
      'Conteúdo muito grande.',
    );
  }
  final bytes = <int>[];
  await for (final chunk in request.read()) {
    if (bytes.length + chunk.length > _maximumBodyBytes) {
      throw const ApiException(
        413,
        'payload_too_large',
        'Conteúdo muito grande.',
      );
    }
    bytes.addAll(chunk);
  }
  try {
    final body = jsonDecode(utf8.decode(bytes));
    if (body is! Map<String, dynamic>) throw const FormatException();
    return body;
  } on FormatException {
    throw const ApiException(
      400,
      'invalid_json',
      'O conteúdo deve ser um objeto JSON válido.',
    );
  }
}

Response _json(int status, Object? data) => Response(
  status,
  body: jsonEncode(data),
  headers: {..._corsHeaders, 'content-type': 'application/json; charset=utf-8'},
);

Response _error(ApiException error) => _json(error.statusCode, {
  'error': {'code': error.code, 'message': error.message},
});
