const createComplaintPermission = '@complaint:create';
const viewResidencyComplaintsPermission = '@complaint:view:residency';
const viewBuildingComplaintsPermission = '@complaint:view:building';
const updateComplaintStatusPermission = '@complaint:update:status';
const respondResidencyComplaintPermission = '@complaint:respond:residency';
const respondBuildingComplaintPermission = '@complaint:respond:building';
const complaintStatuses = {'aberta', 'em_analise', 'encerrada'};
const complaintCategories = {
  'barulho',
  'limpeza',
  'convivencia',
  'areas_comuns',
  'seguranca',
  'outros',
};

class AuthContext {
  const AuthContext({
    required this.userId,
    required this.buildingId,
    this.residencyId,
    this.permissions = const [],
  });
  final String userId;
  final String buildingId;
  final String? residencyId;
  final List<String> permissions;
  bool allows(String permission) =>
      permissions.contains('@core:admin') || permissions.contains(permission);

  bool get canViewBuilding => allows(viewBuildingComplaintsPermission);
  bool get canViewResidency =>
      residencyId != null && allows(viewResidencyComplaintsPermission);
  bool get canRespondBuilding => allows(respondBuildingComplaintPermission);
  bool get canRespondResidency =>
      residencyId != null && allows(respondResidencyComplaintPermission);
}

class ComplaintResponse {
  const ComplaintResponse({
    required this.id,
    required this.authorUserId,
    required this.message,
    required this.createdAt,
    this.isAdministrative = true,
  });
  final String id;
  final String authorUserId;
  final String message;
  final DateTime createdAt;
  final bool isAdministrative;
  Map<String, Object?> toJson() => {
    'id': id,
    'authorUserId': authorUserId,
    'message': message,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'isAdministrative': isAdministrative,
  };
}

class StatusChange {
  const StatusChange({
    required this.id,
    required this.previousStatus,
    required this.status,
    required this.authorUserId,
    required this.createdAt,
  });
  final String id;
  final String? previousStatus;
  final String status;
  final String authorUserId;
  final DateTime createdAt;
  Map<String, Object?> toJson() => {
    'id': id,
    'previousStatus': previousStatus,
    'status': status,
    'authorUserId': authorUserId,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}

class Complaint {
  Complaint({
    required this.id,
    required this.buildingId,
    required this.residentUserId,
    required this.title,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.residencyId,
    this.closedAt,
    List<ComplaintResponse> responses = const [],
    List<StatusChange> history = const [],
  }) : responses = List.unmodifiable(responses),
       history = List.unmodifiable(history);
  final String id;
  final String buildingId;
  final String residentUserId;
  final String? residencyId;
  final String title;
  final String category;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;
  final List<ComplaintResponse> responses;
  final List<StatusChange> history;

  Complaint copyWith({
    String? status,
    DateTime? updatedAt,
    DateTime? closedAt,
    List<ComplaintResponse>? responses,
    List<StatusChange>? history,
  }) => Complaint(
    id: id,
    buildingId: buildingId,
    residentUserId: residentUserId,
    residencyId: residencyId,
    title: title,
    category: category,
    description: description,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    closedAt: closedAt ?? this.closedAt,
    responses: responses ?? this.responses,
    history: history ?? this.history,
  );

  Map<String, Object?> toJson({bool details = true}) => {
    'id': id,
    'buildingId': buildingId,
    'residentUserId': residentUserId,
    'residencyId': residencyId,
    'title': title,
    'category': category,
    'description': description,
    'status': status,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'closedAt': closedAt?.toUtc().toIso8601String(),
    if (details) 'responses': responses.map((r) => r.toJson()).toList(),
    if (details) 'history': history.map((h) => h.toJson()).toList(),
  };
}

class ComplaintQuery {
  const ComplaintQuery({
    required this.buildingId,
    this.residentUserId,
    this.residencyId,
    this.status,
    this.category,
    this.limit = 20,
    this.offset = 0,
  });
  final String buildingId;
  final String? residentUserId;
  final String? residencyId;
  final String? status;
  final String? category;
  final int limit;
  final int offset;
}
