class VisitorAccess {
  const VisitorAccess({
    required this.id,
    required this.buildingId,
    required this.residencyId,
    required this.rg,
    required this.cpf,
    required this.name,
    required this.entryAt,
    this.residencyName,
    this.residencyCode,
  });

  final String id;
  final String buildingId;
  final String residencyId;
  final String? residencyName;
  final String? residencyCode;
  final String rg;
  final String cpf;
  final String name;
  final DateTime entryAt;

  /// Code, then name, then id. Matches the React residency label.
  String get residencyLabel {
    for (final value in [residencyCode, residencyName]) {
      if (value != null && value.isNotEmpty) return value;
    }
    return residencyId;
  }

  factory VisitorAccess.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Invalid visitor access');
    final json = Map<String, dynamic>.from(value);
    final entryAt = json['entryAt'];
    if (json['id'] is! String ||
        json['buildingId'] is! String ||
        json['residencyId'] is! String ||
        json['rg'] is! String ||
        json['cpf'] is! String ||
        json['name'] is! String ||
        entryAt is! String) {
      throw const FormatException('Invalid visitor access');
    }
    return VisitorAccess(
      id: json['id'] as String,
      buildingId: json['buildingId'] as String,
      residencyId: json['residencyId'] as String,
      residencyName: _optionalText(json['residencyName']),
      residencyCode: _optionalText(json['residencyCode']),
      rg: json['rg'] as String,
      cpf: json['cpf'] as String,
      name: json['name'] as String,
      entryAt: DateTime.parse(entryAt),
    );
  }

  static String? _optionalText(Object? value) {
    if (value == null) return null;
    if (value is! String) throw const FormatException('Invalid visitor access');
    return value;
  }
}
