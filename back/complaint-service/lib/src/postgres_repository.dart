import 'package:postgres/postgres.dart';

import 'errors.dart';
import 'models.dart';
import 'repository.dart';

/// Persists one complaint and its append-only history as a single aggregate.
class PostgresComplaintRepository implements ComplaintRepository {
  PostgresComplaintRepository(this._pool);

  final Pool<dynamic> _pool;

  @override
  Future<void> create(Complaint complaint) => _pool.runTx((session) async {
    await session.execute(
      Sql.named('''
        INSERT INTO complaints (
          id, building_id, resident_user_id, title, category, description,
          status, created_at, updated_at, closed_at
        ) VALUES (
          @id, @buildingId, @residentUserId, @title, @category, @description,
          @status, @createdAt, @updatedAt, @closedAt
        )
      '''),
      parameters: {
        'id': complaint.id,
        'buildingId': complaint.buildingId,
        'residentUserId': complaint.residentUserId,
        'title': complaint.title,
        'category': complaint.category,
        'description': complaint.description,
        'status': complaint.status,
        'createdAt': complaint.createdAt.toUtc(),
        'updatedAt': complaint.updatedAt.toUtc(),
        'closedAt': complaint.closedAt?.toUtc(),
      },
    );
    await _appendResponses(session, complaint.id, complaint.responses);
    await _appendHistory(session, complaint.id, complaint.history);
  });

  @override
  Future<Complaint?> find(String id, String buildingId) => _pool.runTx(
    (session) => _load(session, id, buildingId),
    settings: TransactionSettings(
      isolationLevel: IsolationLevel.repeatableRead,
      accessMode: AccessMode.readOnly,
    ),
  );

  @override
  Future<List<Complaint>> list(ComplaintQuery query) async {
    final conditions = <String>['building_id = @buildingId'];
    final parameters = <String, Object?>{
      'buildingId': query.buildingId,
      'limit': query.limit,
      'offset': query.offset,
    };
    if (query.residentUserId != null) {
      conditions.add('resident_user_id = @residentUserId');
      parameters['residentUserId'] = query.residentUserId;
    }
    if (query.status != null) {
      conditions.add('status = @status');
      parameters['status'] = query.status;
    }
    if (query.category != null) {
      conditions.add('category = @category');
      parameters['category'] = query.category;
    }
    final rows = await _pool.execute(
      Sql.named('''
        SELECT * FROM complaints WHERE ${conditions.join(' AND ')}
        ORDER BY created_at DESC, id DESC LIMIT @limit OFFSET @offset
      '''),
      parameters: parameters,
    );
    return rows.map((row) => _complaint(row.toColumnMap())).toList();
  }

  @override
  Future<Complaint> update(
    String id,
    String buildingId,
    Complaint Function(Complaint current) change,
  ) => _pool.runTx((session) async {
    // The lock serializes replies and closure, including across service replicas.
    final current = await _load(session, id, buildingId, lock: true);
    if (current == null) throw ApiException.notFound;
    final updated = change(current);
    _assertAppendOnly(current, updated);
    await session.execute(
      Sql.named('''
        UPDATE complaints SET status = @status, updated_at = @updatedAt,
          closed_at = @closedAt
        WHERE id = @id AND building_id = @buildingId
      '''),
      parameters: {
        'id': id,
        'buildingId': buildingId,
        'status': updated.status,
        'updatedAt': updated.updatedAt.toUtc(),
        'closedAt': updated.closedAt?.toUtc(),
      },
    );
    await _appendResponses(
      session,
      id,
      updated.responses.skip(current.responses.length),
    );
    await _appendHistory(
      session,
      id,
      updated.history.skip(current.history.length),
    );
    return updated;
  });

  Future<Complaint?> _load(
    Session session,
    String id,
    String buildingId, {
    bool lock = false,
  }) async {
    final rows = await session.execute(
      Sql.named('''
        SELECT * FROM complaints WHERE id = @id AND building_id = @buildingId
        ${lock ? 'FOR UPDATE' : ''}
      '''),
      parameters: {'id': id, 'buildingId': buildingId},
    );
    if (rows.isEmpty) return null;
    final responses = await session.execute(
      Sql.named('''
        SELECT * FROM complaint_responses WHERE complaint_id = @id
        ORDER BY created_at ASC, id ASC
      '''),
      parameters: {'id': id},
    );
    final history = await session.execute(
      Sql.named('''
        SELECT * FROM complaint_status_history WHERE complaint_id = @id
        ORDER BY created_at ASC, id ASC
      '''),
      parameters: {'id': id},
    );
    return _complaint(
      rows.single.toColumnMap(),
      responses: responses.map((row) {
        final data = row.toColumnMap();
        return ComplaintResponse(
          id: data['id'] as String,
          authorUserId: data['author_user_id'] as String,
          message: data['message'] as String,
          createdAt: (data['created_at'] as DateTime).toUtc(),
        );
      }).toList(),
      history: history.map((row) {
        final data = row.toColumnMap();
        return StatusChange(
          id: data['id'] as String,
          previousStatus: data['previous_status'] as String?,
          status: data['status'] as String,
          authorUserId: data['author_user_id'] as String,
          createdAt: (data['created_at'] as DateTime).toUtc(),
        );
      }).toList(),
    );
  }

  Complaint _complaint(
    Map<String, Object?> data, {
    List<ComplaintResponse> responses = const [],
    List<StatusChange> history = const [],
  }) => Complaint(
    id: data['id'] as String,
    buildingId: data['building_id'] as String,
    residentUserId: data['resident_user_id'] as String,
    title: data['title'] as String,
    category: data['category'] as String,
    description: data['description'] as String,
    status: data['status'] as String,
    createdAt: (data['created_at'] as DateTime).toUtc(),
    updatedAt: (data['updated_at'] as DateTime).toUtc(),
    closedAt: (data['closed_at'] as DateTime?)?.toUtc(),
    responses: responses,
    history: history,
  );

  Future<void> _appendResponses(
    Session session,
    String complaintId,
    Iterable<ComplaintResponse> responses,
  ) async {
    for (final response in responses) {
      await session.execute(
        Sql.named('''
          INSERT INTO complaint_responses (
            id, complaint_id, author_user_id, message, created_at
          ) VALUES (@id, @complaintId, @authorUserId, @message, @createdAt)
        '''),
        parameters: {
          'id': response.id,
          'complaintId': complaintId,
          'authorUserId': response.authorUserId,
          'message': response.message,
          'createdAt': response.createdAt.toUtc(),
        },
      );
    }
  }

  Future<void> _appendHistory(
    Session session,
    String complaintId,
    Iterable<StatusChange> history,
  ) async {
    for (final entry in history) {
      await session.execute(
        Sql.named('''
          INSERT INTO complaint_status_history (
            id, complaint_id, previous_status, status, author_user_id, created_at
          ) VALUES (
            @id, @complaintId, @previousStatus, @status, @authorUserId, @createdAt
          )
        '''),
        parameters: {
          'id': entry.id,
          'complaintId': complaintId,
          'previousStatus': entry.previousStatus,
          'status': entry.status,
          'authorUserId': entry.authorUserId,
          'createdAt': entry.createdAt.toUtc(),
        },
      );
    }
  }

  void _assertAppendOnly(Complaint current, Complaint updated) {
    if (current.id != updated.id ||
        current.buildingId != updated.buildingId ||
        current.residentUserId != updated.residentUserId ||
        current.title != updated.title ||
        current.category != updated.category ||
        current.description != updated.description ||
        current.createdAt != updated.createdAt ||
        updated.responses.length < current.responses.length ||
        updated.history.length < current.history.length) {
      throw StateError('Complaint content and existing history are immutable.');
    }
    for (var i = 0; i < current.responses.length; i++) {
      final before = current.responses[i];
      final after = updated.responses[i];
      if (before.id != after.id ||
          before.authorUserId != after.authorUserId ||
          before.message != after.message ||
          before.createdAt != after.createdAt) {
        throw StateError('Existing responses are immutable.');
      }
    }
    for (var i = 0; i < current.history.length; i++) {
      final before = current.history[i];
      final after = updated.history[i];
      if (before.id != after.id ||
          before.previousStatus != after.previousStatus ||
          before.status != after.status ||
          before.authorUserId != after.authorUserId ||
          before.createdAt != after.createdAt) {
        throw StateError('Existing status history is immutable.');
      }
    }
  }

  @override
  Future<void> health() async {
    await _pool.execute('SELECT 1');
  }

  @override
  Future<void> close() => _pool.close();
}
