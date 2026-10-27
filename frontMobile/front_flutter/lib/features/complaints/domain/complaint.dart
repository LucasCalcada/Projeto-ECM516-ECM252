enum ComplaintStatus { open, answered, closed }

enum ComplaintScope { mine, building }

class ComplaintResponse {
  const ComplaintResponse({required this.message, required this.createdAt});

  final String message;
  final DateTime createdAt;
}

class Complaint {
  const Complaint({
    required this.id,
    required this.protocol,
    required this.subject,
    required this.description,
    required this.createdAt,
    required this.status,
    this.responses = const [],
  });

  final String id;
  final String protocol;
  final String subject;
  final String description;
  final DateTime createdAt;
  final ComplaintStatus status;
  final List<ComplaintResponse> responses;

  Complaint copyWith({
    ComplaintStatus? status,
    List<ComplaintResponse>? responses,
  }) => Complaint(
    id: id,
    protocol: protocol,
    subject: subject,
    description: description,
    createdAt: createdAt,
    status: status ?? this.status,
    responses: List<ComplaintResponse>.unmodifiable(
      responses ?? this.responses,
    ),
  );
}
