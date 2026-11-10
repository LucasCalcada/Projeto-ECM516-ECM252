class CommunicationPost {
  const CommunicationPost({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.eventAt,
    this.residencyIds = const [],
  });

  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? eventAt;

  /// Residencies addressed by the post. Empty means the whole building.
  final List<String> residencyIds;

  bool get isBuildingWide => residencyIds.isEmpty;

  factory CommunicationPost.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['id'] is! String ||
        value['title'] is! String ||
        value['description'] is! String ||
        value['createdAt'] is! String) {
      throw const FormatException('Invalid post');
    }
    final residencyIds = value['residencyIds'];
    if (residencyIds != null &&
        (residencyIds is! List || !residencyIds.every((id) => id is String))) {
      throw const FormatException('Invalid post residencies');
    }
    return CommunicationPost(
      id: value['id'] as String,
      title: value['title'] as String,
      description: value['description'] as String,
      createdAt: DateTime.parse(value['createdAt'] as String).toLocal(),
      eventAt: value['eventAt'] == null
          ? null
          : DateTime.parse(value['eventAt'] as String).toLocal(),
      residencyIds: residencyIds == null
          ? const []
          : List<String>.unmodifiable(residencyIds as List),
    );
  }
}
