import 'complaint.dart';

abstract interface class ComplaintsRepository {
  Future<List<Complaint>> list({
    required ComplaintScope scope,
    ComplaintStatus? status,
    String? category,
    int limit = 20,
    int offset = 0,
  });

  Future<Complaint> getDetail(String id);

  Future<Complaint> create({
    required String title,
    required String category,
    required String description,
  });

  Future<Complaint> respond({
    required String complaintId,
    required String message,
  });

  Future<Complaint> close({required String complaintId});

  Future<Complaint> changeStatus({
    required String complaintId,
    required ComplaintStatus status,
  });
}

enum ComplaintFailure {
  validation,
  forbidden,
  notFound,
  conflict,
  network,
  server,
  invalidResponse,
}

class ComplaintException implements Exception {
  const ComplaintException(this.failure, {this.code});
  final ComplaintFailure failure;
  final String? code;
}

/// Raised by the host adapter when its authenticated session is no longer valid.
class ComplaintSessionExpired implements Exception {
  const ComplaintSessionExpired();
}
