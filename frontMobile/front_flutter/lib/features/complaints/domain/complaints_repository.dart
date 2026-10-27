import 'complaint.dart';

abstract interface class ComplaintsRepository {
  Future<List<Complaint>> list({required ComplaintScope scope});

  Future<Complaint> create({
    required String subject,
    required String description,
  });

  Future<Complaint> respond({
    required String complaintId,
    required String message,
  });

  Future<Complaint> close({required String complaintId});
}

/// Raised by the host adapter when its authenticated session is no longer valid.
class ComplaintSessionExpired implements Exception {
  const ComplaintSessionExpired();
}
