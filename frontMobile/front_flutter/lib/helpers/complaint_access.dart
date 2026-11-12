import 'dart:convert';

import '../types/complaint.dart';

const complaintPermissions = [
  '@complaint:create',
  '@complaint:view:residency',
  '@complaint:view:building',
  '@complaint:update:status',
  '@complaint:respond:residency',
  '@complaint:respond:building',
];

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
    this.residencyId,
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
    String? residencyId,
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
      residencyId: residentAccess ? residencyId : null,
      isSignedIn: true,
    );
  }

  final String userId;
  final String buildingId;
  final String? residencyId;
  final List<String> permissions;
  final DateTime? expiresAt;
  final bool residentAccess;
  final bool isSignedIn;

  bool get isExpired =>
      expiresAt != null && !expiresAt!.isAfter(DateTime.now());

  bool get _valid =>
      isSignedIn && !isExpired && userId.isNotEmpty && buildingId.isNotEmpty;

  bool _allows(String permission) =>
      _valid &&
      (permissions.contains('@core:admin') || permissions.contains(permission));
  bool get canAccess =>
      _valid &&
      (permissions.contains('@core:admin') ||
          permissions.any(complaintPermissions.contains));
  bool get canViewBuilding => _allows('@complaint:view:building');
  bool get canViewResidency =>
      residencyId?.isNotEmpty == true && _allows('@complaint:view:residency');
  bool get canRead => canViewBuilding || canViewResidency;
  bool get canCreate => _allows('@complaint:create');
  bool get canChangeStatus => _allows('@complaint:update:status');
  bool canReadScope(ComplaintScope scope) =>
      scope == ComplaintScope.building ? canViewBuilding : canViewResidency;
  bool canRespondTo(Complaint complaint) =>
      _allows('@complaint:respond:building') ||
      (residencyId != null &&
          complaint.residencyId == residencyId &&
          _allows('@complaint:respond:residency'));

  ComplaintScope get scope =>
      canViewBuilding ? ComplaintScope.building : ComplaintScope.mine;

  /// A stable value for the current identity, context, and authorization grant.
  /// It intentionally contains no bearer token or user display name.
  String get sessionIdentity => jsonEncode([
    isSignedIn,
    userId,
    buildingId,
    permissions,
    expiresAt?.toUtc().microsecondsSinceEpoch,
    residentAccess,
    residencyId,
  ]);

  String get key => sessionIdentity;
}
