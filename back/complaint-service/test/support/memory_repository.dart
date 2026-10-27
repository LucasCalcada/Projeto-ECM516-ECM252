import 'package:complaint_service/src/errors.dart';
import 'package:complaint_service/src/models.dart';
import 'package:complaint_service/src/repository.dart';

/// Test double. Production always uses PostgreSQL.
class MemoryComplaintRepository implements ComplaintRepository {
  final Map<String, Complaint> complaints = {};

  @override
  Future<void> create(Complaint complaint) async {
    complaints[complaint.id] = complaint;
  }

  @override
  Future<Complaint?> find(String id, String buildingId) async {
    final complaint = complaints[id];
    return complaint?.buildingId == buildingId ? complaint : null;
  }

  @override
  Future<List<Complaint>> list(ComplaintQuery query) async {
    final results =
        complaints.values
            .where(
              (c) =>
                  c.buildingId == query.buildingId &&
                  (query.residentUserId == null ||
                      c.residentUserId == query.residentUserId) &&
                  (query.status == null || c.status == query.status) &&
                  (query.category == null || c.category == query.category),
            )
            .toList()
          ..sort((a, b) {
            final date = b.createdAt.compareTo(a.createdAt);
            return date != 0 ? date : b.id.compareTo(a.id);
          });
    return results.skip(query.offset).take(query.limit).toList();
  }

  @override
  Future<Complaint> update(
    String id,
    String buildingId,
    Complaint Function(Complaint current) change,
  ) async {
    // No await between read/change/write, matching the atomic repository contract.
    final current = complaints[id];
    if (current == null || current.buildingId != buildingId) {
      throw ApiException.notFound;
    }
    final updated = change(current);
    complaints[id] = updated;
    return updated;
  }

  @override
  Future<void> health() async {}
  @override
  Future<void> close() async {}
}
