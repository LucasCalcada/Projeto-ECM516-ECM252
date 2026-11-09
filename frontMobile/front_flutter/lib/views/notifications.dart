import 'package:flutter/material.dart';

import '../components/notifications/notification_create_form.dart';
import '../helpers/communication_service.dart';
import '../helpers/core_service.dart';
import '../lang/app_localizations.dart';
import '../types/user_session.dart';

const manageNotificationsPermission = '@communication:post:manage';

/// Sends notifications. Residents read them on the Home screen; this screen is
/// only offered with [manageNotificationsPermission] and the service
/// authorizes each request again.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
    super.key,
    required this.service,
    required this.coreService,
    required this.session,
    required this.onSessionExpired,
  });

  final CommunicationService service;
  final CoreService coreService;
  final UserSession session;
  final VoidCallback onSessionExpired;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (!session.allows([manageNotificationsPermission])) {
      return Center(child: Text(strings.text('menu.noPermission')));
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(strings.text('notifications.subtitle')),
            ),
            Expanded(
              child: NotificationCreateForm(
                service: service,
                coreService: coreService,
                session: session,
                onSessionExpired: onSessionExpired,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
