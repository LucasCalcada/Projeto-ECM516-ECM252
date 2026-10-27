import 'dart:convert';

import 'complaint.dart';

/// Presentation permissions supplied by the host application's selected session.
/// The repository remains responsible for server authorization.
class ComplaintAccess {
  const ComplaintAccess._({
    required this.userId,
    required this.buildingId,
    required this.permissions,
    required this.expiresAt,
    required this.residentAccess,
    required this.isSignedIn,
  });

  const ComplaintAccess.signedOut()
    : this._(
        userId: '',
        buildingId: '',
        permissions: const [],
        expiresAt: null,
        residentAccess: false,
        isSignedIn: false,
      );

  const ComplaintAccess.denied()
    : this._(
        userId: '',
        buildingId: '',
        permissions: const [],
        expiresAt: null,
        residentAccess: false,
        isSignedIn: true,
      );

  factory ComplaintAccess.fromSession({
    required String userId,
    required String buildingId,
    required List<String> permissions,
    required DateTime expiresAt,
    bool residentAccess = true,
  }) {
    if (userId.trim().isEmpty || buildingId.trim().isEmpty) {
      return const ComplaintAccess.signedOut();
    }
    final normalizedPermissions = permissions.toSet().toList()..sort();
    return ComplaintAccess._(
      userId: userId,
      buildingId: buildingId,
      permissions: List<String>.unmodifiable(normalizedPermissions),
      expiresAt: expiresAt,
      residentAccess: residentAccess,
      isSignedIn: true,
    );
  }

  final String userId;
  final String buildingId;
  final List<String> permissions;
  final DateTime? expiresAt;
  final bool residentAccess;
  final bool isSignedIn;

  bool get isExpired =>
      expiresAt != null && !expiresAt!.isAfter(DateTime.now());

  bool get canManage =>
      isSignedIn && !isExpired && permissions.contains('@complaint:manage');

  bool get canRead => isSignedIn && !isExpired && (residentAccess || canManage);

  bool get canCreate => canRead && residentAccess && !canManage;

  ComplaintScope get scope =>
      canManage ? ComplaintScope.building : ComplaintScope.mine;

  /// A stable value for the current identity, context, and authorization grant.
  /// It intentionally contains no bearer token or user display name.
  String get sessionIdentity => jsonEncode([
    isSignedIn,
    userId,
    buildingId,
    permissions,
    expiresAt?.toUtc().microsecondsSinceEpoch,
    residentAccess,
  ]);

  String get key => sessionIdentity;
}
