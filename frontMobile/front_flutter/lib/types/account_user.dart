class AccountUser {
  const AccountUser({
    required this.userId,
    required this.userName,
    required this.buildingName,
    this.buildingId,
    this.residencyName,
  });

  final String userId;
  final String userName;
  final String buildingName;
  final String? buildingId;
  final String? residencyName;

  factory AccountUser.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['userId'] is! String ||
        (value['userId'] as String).isEmpty ||
        value['userName'] is! String) {
      throw const FormatException('Invalid account user');
    }
    return AccountUser(
      userId: value['userId'] as String,
      userName: value['userName'] as String,
      buildingName: value['buildingName'] as String? ?? '',
      buildingId: value['buildingId'] as String?,
      residencyName: value['residencyName'] as String?,
    );
  }
}
