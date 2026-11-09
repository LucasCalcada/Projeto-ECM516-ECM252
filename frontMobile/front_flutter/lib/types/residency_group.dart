class ResidencyOption {
  const ResidencyOption({required this.id, required this.name});

  final String id;
  final String name;
}

/// Residencies of a building grouped by tower or block.
class ResidencyGroup {
  const ResidencyGroup({
    required this.id,
    required this.name,
    required this.residencies,
  });

  final String id;
  final String name;
  final List<ResidencyOption> residencies;

  /// Parses `residentData` from the core `GET /building/:id/details` route.
  static List<ResidencyGroup> listFromBuildingDetails(Object? value) {
    if (value is! Map<String, dynamic> || value['residentData'] is! List) {
      throw const FormatException('Invalid building details');
    }
    final groups = <ResidencyGroup>[];
    for (final group in value['residentData'] as List) {
      if (group is! Map<String, dynamic> ||
          group['id'] is! String ||
          group['residencies'] is! List) {
        throw const FormatException('Invalid residency group');
      }
      final residencies = <ResidencyOption>[];
      for (final residency in group['residencies'] as List) {
        if (residency is! Map<String, dynamic> || residency['id'] is! String) {
          throw const FormatException('Invalid residency');
        }
        final name = residency['name'];
        if (name is String && name.isNotEmpty) {
          residencies.add(
            ResidencyOption(id: residency['id'] as String, name: name),
          );
        }
      }
      if (residencies.isEmpty) continue;
      residencies.sort((a, b) => a.name.compareTo(b.name));
      groups.add(
        ResidencyGroup(
          id: group['id'] as String,
          name: group['name'] as String? ?? '',
          residencies: List.unmodifiable(residencies),
        ),
      );
    }
    groups.sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(groups);
  }
}
