import 'package:flutter/material.dart';

import '../components/notifications/notification_create_form.dart';
import '../components/notifications/notification_list.dart';
import '../components/notifications/notification_view_mode.dart';
import '../helpers/communication_service.dart';
import '../helpers/core_service.dart';
import '../lang/app_localizations.dart';
import '../types/user_session.dart';

/// Every user can read the notifications addressed to them. Creating and
/// managing notifications is only offered with the communication permission;
/// the service authorizes each request again.
class NotificationsScreen extends StatefulWidget {
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

  static List<NotificationViewMode> availableModes(UserSession session) => [
    NotificationViewMode.inbox,
    if (session.allows([manageNotificationsPermission])) ...[
      NotificationViewMode.create,
      NotificationViewMode.manage,
    ],
  ];

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationViewMode _mode = NotificationViewMode.inbox;

  static const _icons = {
    NotificationViewMode.inbox: Icons.inbox_outlined,
    NotificationViewMode.create: Icons.campaign_outlined,
    NotificationViewMode.manage: Icons.tune,
  };

  Widget _content(NotificationViewMode mode) => switch (mode) {
    NotificationViewMode.create => NotificationCreateForm(
      service: widget.service,
      coreService: widget.coreService,
      session: widget.session,
      onSessionExpired: widget.onSessionExpired,
    ),
    NotificationViewMode.manage => NotificationList(
      key: const ValueKey('notifications-manage'),
      service: widget.service,
      coreService: widget.coreService,
      session: widget.session,
      onSessionExpired: widget.onSessionExpired,
      manage: true,
    ),
    NotificationViewMode.inbox => NotificationList(
      key: const ValueKey('notifications-inbox'),
      service: widget.service,
      coreService: widget.coreService,
      session: widget.session,
      onSessionExpired: widget.onSessionExpired,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final modes = NotificationsScreen.availableModes(widget.session);
    final mode = modes.contains(_mode) ? _mode : modes.first;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (modes.length > 1) ...[
                    SegmentedButton<NotificationViewMode>(
                      key: const Key('notification-modes'),
                      showSelectedIcon: false,
                      segments: [
                        for (final option in modes)
                          ButtonSegment(
                            value: option,
                            icon: Icon(_icons[option]),
                            label: Text(
                              strings.text(
                                'notifications.views.${option.name}',
                              ),
                            ),
                          ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (selection) =>
                          setState(() => _mode = selection.single),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(strings.text('notifications.subtitle.${mode.name}')),
                ],
              ),
            ),
            Expanded(child: _content(mode)),
          ],
        ),
      ),
    );
  }
}
