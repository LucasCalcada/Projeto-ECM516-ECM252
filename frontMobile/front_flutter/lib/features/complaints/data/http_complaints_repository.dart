import '../../../helpers/api_client.dart';
import '../../../types/api_failure.dart';
import '../domain/complaint.dart';
import '../domain/complaints_repository.dart';

class HttpComplaintsRepository implements ComplaintsRepository {
  const HttpComplaintsRepository(this.client, {required this.token});
  final ApiClient client;
  final String token;

  Future<T> _read<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      if (error.failure == ApiFailure.unauthorized) {
        throw const ComplaintSessionExpired();
      }
      throw ComplaintException(switch (error.statusCode) {
        400 || 413 || 415 => ComplaintFailure.validation,
        403 => ComplaintFailure.forbidden,
        404 => ComplaintFailure.notFound,
        409 => ComplaintFailure.conflict,
        _ => switch (error.failure) {
          ApiFailure.network || ApiFailure.timeout => ComplaintFailure.network,
          ApiFailure.server => ComplaintFailure.server,
          _ => ComplaintFailure.invalidResponse,
        },
      }, code: error.code);
    } on FormatException {
      throw const ComplaintException(ComplaintFailure.invalidResponse);
    }
  }

  @override
  Future<List<Complaint>> list({
    required ComplaintScope scope,
    ComplaintStatus? status,
    String? category,
    int limit = 20,
    int offset = 0,
  }) => _read(() async {
    final value = await client.get(
      scope == ComplaintScope.mine ? '/complaints/residency' : '/complaints',
      token: token,
      query: {
        if (status != null) 'status': status.apiValue,
        'category': ?category,
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    if (value is! List) throw const FormatException('list');
    return List<Complaint>.unmodifiable(
      value.map((item) => Complaint.fromJson(item, details: false)),
    );
  });

  @override
  Future<Complaint> getDetail(String id) => _read(
    () async => Complaint.fromJson(
      await client.get('/complaints/${Uri.encodeComponent(id)}', token: token),
      details: true,
    ),
  );

  @override
  Future<Complaint> create({
    required String title,
    required String category,
    required String description,
  }) => _read(
    () async => Complaint.fromJson(
      await client.post(
        '/complaints',
        token: token,
        body: {
          'title': title.trim(),
          'category': category,
          'description': description.trim(),
        },
      ),
      details: true,
    ),
  );

  @override
  Future<Complaint> respond({
    required String complaintId,
    required String message,
  }) => _read(
    () async => Complaint.fromJson(
      await client.post(
        '/complaints/${Uri.encodeComponent(complaintId)}/responses',
        token: token,
        body: {'message': message.trim()},
      ),
      details: true,
    ),
  );

  @override
  Future<Complaint> changeStatus({
    required String complaintId,
    required ComplaintStatus status,
  }) => _read(
    () async => Complaint.fromJson(
      await client.patch(
        '/complaints/${Uri.encodeComponent(complaintId)}/status',
        token: token,
        body: {'status': status.apiValue},
      ),
      details: true,
    ),
  );

  @override
  Future<Complaint> close({required String complaintId}) =>
      changeStatus(complaintId: complaintId, status: ComplaintStatus.closed);
}
