import 'package:uuid/uuid.dart';

import 'errors.dart';
import 'models.dart';
import 'repository.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

class ComplaintService {
  ComplaintService(this.repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ComplaintRepository repository;
  final DateTime Function() _now;
  static const _uuid = Uuid();

  Future<Complaint> create(AuthContext auth, Map<String, Object?> body) async {
    if (auth.residencyId == null) throw ApiException.forbidden;
    _onlyFields(body, {'title', 'category', 'description'});
    final title = _text(body, 'title', 200);
    final description = _text(body, 'description', 10000);
    final category = _choice(body['category'], complaintCategories, 'category');
    final now = _now().toUtc();
    final complaint = Complaint(
      id: _uuid.v4(),
      buildingId: auth.buildingId,
      residentUserId: auth.userId,
      title: title,
      category: category,
      description: description,
      status: 'aberta',
      createdAt: now,
      updatedAt: now,
      history: [
        StatusChange(
          id: _uuid.v4(),
          previousStatus: null,
          status: 'aberta',
          authorUserId: auth.userId,
          createdAt: now,
        ),
      ],
    );
    await repository.create(complaint);
    return complaint;
  }

  Future<List<Complaint>> list(
    AuthContext auth,
    Map<String, String> query, {
    bool mine = false,
  }) async {
    if (!mine) _requireAdmin(auth);
    if (query.keys.any(
      (key) => !{'status', 'category', 'limit', 'offset'}.contains(key),
    )) {
      throw const ApiException(400, 'invalid_query', 'Filtro desconhecido.');
    }
    final status = query.containsKey('status')
        ? _choice(query['status'], complaintStatuses, 'status')
        : null;
    final category = query.containsKey('category')
        ? _choice(query['category'], complaintCategories, 'category')
        : null;
    return repository.list(
      ComplaintQuery(
        buildingId: auth.buildingId,
        residentUserId: mine ? auth.userId : null,
        status: status,
        category: category,
        limit: _integer(query['limit'], 20, 1, 100, 'limit'),
        offset: _integer(query['offset'], 0, 0, 2147483647, 'offset'),
      ),
    );
  }

  Future<Complaint> detail(AuthContext auth, String id) async {
    final complaint = await repository.find(_id(id), auth.buildingId);
    if (complaint == null ||
        (!auth.canManage && complaint.residentUserId != auth.userId)) {
      throw ApiException.notFound;
    }
    return complaint;
  }

  Future<Complaint> respond(
    AuthContext auth,
    String id,
    Map<String, Object?> body,
  ) async {
    _requireAdmin(auth);
    _onlyFields(body, {'message'});
    final message = _text(body, 'message', 5000);
    return repository.update(_id(id), auth.buildingId, (current) {
      _requireOpen(current);
      final now = _now().toUtc();
      return current.copyWith(
        updatedAt: now,
        responses: [
          ...current.responses,
          ComplaintResponse(
            id: _uuid.v4(),
            authorUserId: auth.userId,
            message: message,
            createdAt: now,
          ),
        ],
      );
    });
  }

  Future<Complaint> changeStatus(
    AuthContext auth,
    String id,
    Map<String, Object?> body,
  ) async {
    _requireAdmin(auth);
    _onlyFields(body, {'status'});
    final status = _choice(body['status'], complaintStatuses, 'status');
    return repository.update(_id(id), auth.buildingId, (current) {
      _requireOpen(current);
      if (status == 'aberta' || status == current.status) {
        throw const ApiException(
          409,
          'invalid_transition',
          'Transição de status não permitida.',
        );
      }
      if (status == 'encerrada' && current.responses.isEmpty) {
        throw const ApiException(
          409,
          'response_required',
          'Registre uma resposta antes de encerrar a reclamação.',
        );
      }
      final now = _now().toUtc();
      return current.copyWith(
        status: status,
        updatedAt: now,
        closedAt: status == 'encerrada' ? now : null,
        history: [
          ...current.history,
          StatusChange(
            id: _uuid.v4(),
            previousStatus: current.status,
            status: status,
            authorUserId: auth.userId,
            createdAt: now,
          ),
        ],
      );
    });
  }

  void _requireAdmin(AuthContext auth) {
    if (!auth.canManage) throw ApiException.forbidden;
  }

  void _requireOpen(Complaint complaint) {
    if (complaint.status == 'encerrada') {
      throw const ApiException(
        409,
        'complaint_closed',
        'A reclamação já está encerrada.',
      );
    }
  }

  String _id(String value) {
    if (!_uuidPattern.hasMatch(value)) {
      throw const ApiException(400, 'invalid_id', 'Identificador inválido.');
    }
    return value.toLowerCase();
  }

  void _onlyFields(Map<String, Object?> body, Set<String> fields) {
    if (body.keys.any((key) => !fields.contains(key))) {
      throw const ApiException(400, 'invalid_payload', 'Campo não permitido.');
    }
  }

  String _text(Map<String, Object?> body, String field, int maxLength) {
    final raw = body[field];
    if (raw is! String ||
        raw.contains('\u0000') ||
        raw.trim().isEmpty ||
        raw.trim().length > maxLength) {
      throw ApiException(
        400,
        'invalid_payload',
        'O campo $field deve conter de 1 a $maxLength caracteres.',
      );
    }
    return raw.trim();
  }

  String _choice(Object? value, Set<String> options, String field) {
    if (value is! String || !options.contains(value)) {
      throw ApiException(400, 'invalid_payload', 'Valor inválido para $field.');
    }
    return value;
  }

  int _integer(String? value, int fallback, int min, int max, String field) {
    if (value == null) return fallback;
    final number = RegExp(r'^\d+$').hasMatch(value)
        ? int.tryParse(value)
        : null;
    if (number == null || number < min || number > max) {
      throw ApiException(400, 'invalid_query', 'Valor inválido para $field.');
    }
    return number;
  }
}
