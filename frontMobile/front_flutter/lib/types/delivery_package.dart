/// Transport values match the delivery service used by the React app.
enum DeliveryStatus {
  pending('PENDING'),
  delivered('DELIVERED'),
  canceled('CANCELED'),
  unknown('');

  const DeliveryStatus(this.value);

  final String value;

  /// Unknown values are kept neutral and never enable status-dependent actions.
  static DeliveryStatus parse(Object? raw) => values.firstWhere(
    (status) => status.value.isNotEmpty && status.value == raw,
    orElse: () => unknown,
  );
}

enum PackageScope { building, residency }

class DeliveryPackage {
  const DeliveryPackage({
    required this.id,
    required this.buildingId,
    required this.residencyId,
    required this.residencyName,
    required this.description,
    required this.status,
    required this.createdAt,
    this.deliveredAt,
  });

  final String id;
  final String buildingId;
  final String residencyId;
  final String residencyName;
  final String description;
  final DeliveryStatus status;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  DeliveryPackage copyWith({DeliveryStatus? status, DateTime? deliveredAt}) =>
      DeliveryPackage(
        id: id,
        buildingId: buildingId,
        residencyId: residencyId,
        residencyName: residencyName,
        description: description,
        status: status ?? this.status,
        createdAt: createdAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
      );

  /// Dates arrive in UTC and are converted for display only.
  factory DeliveryPackage.fromJson(Object? json) {
    final map = json as Map<String, dynamic>;
    final delivered = map['deliveredAt'];
    return DeliveryPackage(
      id: map['id'] as String,
      buildingId: map['buildingId'] as String,
      residencyId: map['residencyId'] as String,
      residencyName: map['residencyName'] as String,
      description: map['description'] as String,
      status: DeliveryStatus.parse(map['status']),
      createdAt: DateTime.parse(map['createdAt'] as String),
      deliveredAt: delivered is String ? DateTime.parse(delivered) : null,
    );
  }
}

class ResidencyOption {
  const ResidencyOption({required this.id, required this.name});

  final String id;
  final String name;
}
