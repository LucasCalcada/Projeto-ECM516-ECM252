class ResidentGroup {
  const ResidentGroup({required this.id, required this.name});
  final String id;
  final String name;

  factory ResidentGroup.fromJson(Object? value) {
    final json = _object(value);
    return ResidentGroup(id: _id(json), name: _text(json, 'name'));
  }
}

class ResidentResidency {
  const ResidentResidency({required this.id, required this.name, required this.code});
  final String id;
  final String name;
  final String code;

  factory ResidentResidency.fromJson(Object? value) {
    final json = _object(value);
    return ResidentResidency(id: _id(json), name: _text(json, 'name'), code: _text(json, 'code'));
  }
}

class Resident {
  const Resident({required this.id, required this.name, required this.permissions});
  final String id;
  final String name;
  final List<String> permissions;

  factory Resident.fromJson(Object? value) {
    final json = _object(value);
    final permissions = json['permissions'];
    if (permissions != null && (permissions is! List || !permissions.every((item) => item is String))) {
      throw const FormatException('Invalid resident permissions');
    }
    return Resident(
      id: _id(json),
      name: _text(json, 'name'),
      permissions: List<String>.unmodifiable(permissions as List? ?? const []),
    );
  }
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) throw const FormatException('Invalid resident data');
  return value;
}

String _id(Map<String, dynamic> json) {
  final id = json['id'];
  if (id is! String || id.isEmpty) throw const FormatException('Missing resident identifier');
  return id;
}

String _text(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value != null && value is! String) throw const FormatException('Invalid resident text');
  return value as String? ?? '';
}
