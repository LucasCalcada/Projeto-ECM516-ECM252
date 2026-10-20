class CommunicationPost {
  const CommunicationPost({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.eventAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? eventAt;

  factory CommunicationPost.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['id'] is! String ||
        value['title'] is! String ||
        value['description'] is! String ||
        value['createdAt'] is! String) {
      throw const FormatException('Invalid post');
    }
    return CommunicationPost(
      id: value['id'] as String,
      title: value['title'] as String,
      description: value['description'] as String,
      createdAt: DateTime.parse(value['createdAt'] as String).toLocal(),
      eventAt: value['eventAt'] == null
          ? null
          : DateTime.parse(value['eventAt'] as String).toLocal(),
    );
  }
}
