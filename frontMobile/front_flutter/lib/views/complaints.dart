import 'package:flutter/material.dart';

import '../features/complaints/complaints.dart';
import '../types/user_session.dart';

/// Authenticated entry point; the feature also supports a standalone preview.
class ComplaintsView extends StatelessWidget {
  const ComplaintsView({
    super.key,
    required this.session,
    required this.repository,
    required this.screenKey,
    required this.onSessionExpired,
  });

  final UserSession session;
  final ComplaintsRepository repository;
  final GlobalKey<ComplaintsScreenState> screenKey;
  final VoidCallback onSessionExpired;

  @override
  Widget build(BuildContext context) => ComplaintsScreen(
    key: screenKey,
    access: ComplaintAccess.fromSession(
      userId: session.userId,
      buildingId: session.buildingId,
      permissions: session.permissions,
      expiresAt: session.expiresAt,
      residentAccess: session.residencyId?.isNotEmpty == true,
      residencyId: session.residencyId,
    ),
    repository: repository,
    buildingName: session.buildingName,
    onSessionExpired: onSessionExpired,
    shellManaged: true,
  );
}
