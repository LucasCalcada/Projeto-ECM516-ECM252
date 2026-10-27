import 'models.dart';

abstract interface class ComplaintRepository {
  Future<void> create(Complaint complaint);
  Future<Complaint?> find(String id, String buildingId);
  Future<List<Complaint>> list(ComplaintQuery query);

  /// Loads and locks the aggregate, applies [change], and persists atomically.
  /// Throws ApiException.notFound if the id does not belong to the building.
  Future<Complaint> update(
    String id,
    String buildingId,
    Complaint Function(Complaint current) change,
  );
  Future<void> health();
  Future<void> close();
}
