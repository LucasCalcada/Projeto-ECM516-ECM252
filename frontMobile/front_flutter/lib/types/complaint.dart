enum ComplaintStatus {
  open('aberta'),
  inAnalysis('em_analise'),
  closed('encerrada'),
  unknown('unknown');

  const ComplaintStatus(this.apiValue);
  final String apiValue;

  static ComplaintStatus parse(Object? value) => values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => ComplaintStatus.unknown,
  );
}

const complaintCategories = [
  'barulho',
  'limpeza',
  'convivencia',
  'areas_comuns',
  'seguranca',
  'outros',
];

enum ComplaintScope { mine, building }

class ComplaintResponse {
  const ComplaintResponse({
    required this.message,
    required this.createdAt,
    this.isAdministrative = true,
  });

  final String message;
  final DateTime createdAt;
  final bool isAdministrative;
}

class ComplaintStatusChange {
  const ComplaintStatusChange({
    required this.status,
    required this.createdAt,
    this.previousStatus,
  });
  final ComplaintStatus status;
  final ComplaintStatus? previousStatus;
  final DateTime createdAt;
}

class Complaint {
  const Complaint({
    required this.id,
    required this.title,
    this.category = 'outros',
    required this.description,
    required this.createdAt,
    required this.status,
    this.responses = const [],
    this.history = const [],
    DateTime? updatedAt,
    this.closedAt,
    this.hasDetails = true,
    this.residencyId,
  }) : updatedAt = updatedAt ?? createdAt;

  final String id;
  final String? residencyId;
  final String title;
  final String category;
  final String description;
  final DateTime createdAt;
  final ComplaintStatus status;
  final List<ComplaintResponse> responses;
  final List<ComplaintStatusChange> history;
  final DateTime updatedAt;
  final DateTime? closedAt;
  final bool hasDetails;

  factory Complaint.fromJson(Object? value, {required bool details}) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Complaint');
    }
    String text(String key) {
      final result = value[key];
      if (result is! String || result.isEmpty) throw FormatException(key);
      return result;
    }

    DateTime date(String key) => DateTime.parse(text(key));
    final category = text('category');
    if (!complaintCategories.contains(category)) {
      throw const FormatException('category');
    }
    List<T> collection<T>(String key, T Function(Map<String, dynamic>) parse) {
      if (!details) return <T>[];
      final items = value[key];
      if (items is! List) throw FormatException(key);
      return List<T>.unmodifiable(
        items.map((item) {
          if (item is! Map<String, dynamic>) throw FormatException(key);
          return parse(item);
        }),
      );
    }

    return Complaint(
      id: text('id'),
      residencyId: value['residencyId'] as String?,
      title: text('title'),
      category: category,
      description: text('description'),
      createdAt: date('createdAt'),
      updatedAt: date('updatedAt'),
      closedAt: value['closedAt'] == null ? null : date('closedAt'),
      status: ComplaintStatus.parse(value['status']),
      hasDetails: details,
      responses: collection('responses', (item) {
        if (item['message'] is! String || item['createdAt'] is! String) {
          throw const FormatException('response');
        }
        return ComplaintResponse(
          message: item['message'] as String,
          createdAt: DateTime.parse(item['createdAt'] as String),
          isAdministrative: item['isAdministrative'] == true,
        );
      }),
      history: collection('history', (item) {
        if (item['createdAt'] is! String) {
          throw const FormatException('history');
        }
        return ComplaintStatusChange(
          status: ComplaintStatus.parse(item['status']),
          previousStatus: item['previousStatus'] == null
              ? null
              : ComplaintStatus.parse(item['previousStatus']),
          createdAt: DateTime.parse(item['createdAt'] as String),
        );
      }),
    );
  }

  Complaint copyWith({
    ComplaintStatus? status,
    List<ComplaintResponse>? responses,
    List<ComplaintStatusChange>? history,
    DateTime? updatedAt,
    DateTime? closedAt,
    bool? hasDetails,
  }) => Complaint(
    id: id,
    residencyId: residencyId,
    title: title,
    category: category,
    description: description,
    createdAt: createdAt,
    status: status ?? this.status,
    responses: List<ComplaintResponse>.unmodifiable(
      responses ?? this.responses,
    ),
    history: List<ComplaintStatusChange>.unmodifiable(history ?? this.history),
    updatedAt: updatedAt ?? this.updatedAt,
    closedAt: closedAt ?? this.closedAt,
    hasDetails: hasDetails ?? this.hasDetails,
  );
}
