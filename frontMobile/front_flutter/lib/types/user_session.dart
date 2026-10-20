import 'dart:convert';

class UserSession {
  const UserSession({
    required this.token,
    required this.userId,
    required this.buildingId,
    required this.buildingName,
    required this.permissions,
    required this.expiresAt,
    this.residencyName,
  });

  final String token;
  final String userId;
  final String buildingId;
  final String buildingName;
  final String? residencyName;
  final List<String> permissions;
  final DateTime expiresAt;

  bool get isExpired => !expiresAt.isAfter(DateTime.now());

  bool allows(List<String> requiredPermissions) =>
      requiredPermissions.isEmpty ||
      permissions.contains('@core:admin') ||
      requiredPermissions.any(permissions.contains);

  /// Claims are used for presentation only. Services validate the JWT signature
  /// and authorize every request.
  factory UserSession.fromToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('Invalid user token');
    }
    final data = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (data is! Map<String, dynamic> ||
        data['tokenKind'] != 'user' ||
        data['userId'] is! String ||
        (data['userId'] as String).isEmpty ||
        data['buildingId'] is! String ||
        (data['buildingId'] as String).isEmpty ||
        data['permissions'] is! List ||
        !(data['permissions'] as List).every((item) => item is String) ||
        data['exp'] is! int) {
      throw const FormatException('Invalid user claims');
    }
    return UserSession(
      token: token,
      userId: data['userId'] as String,
      buildingId: data['buildingId'] as String,
      buildingName: data['buildingName'] as String? ?? '',
      residencyName: data['residencyName'] as String?,
      permissions: List<String>.unmodifiable(data['permissions'] as List),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        (data['exp'] as int) * 1000,
        isUtc: true,
      ),
    );
  }
}
