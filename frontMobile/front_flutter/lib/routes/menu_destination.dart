import 'package:flutter/material.dart';

import '../types/user_session.dart';
import 'app_routes.dart';

class MenuDestination {
  const MenuDestination(
    this.route,
    this.label,
    this.icon, {
    this.permissions = const [],
    this.available = false,
    this.hideWithoutPermission = false,
  });

  final String route;
  final String label;
  final IconData icon;
  final List<String> permissions;
  final bool available;

  /// Hides the entry instead of showing it locked when permissions are missing.
  final bool hideWithoutPermission;

  bool isVisibleTo(UserSession session) =>
      !hideWithoutPermission || session.allows(permissions);

  bool canOpen(UserSession session) =>
      available && !session.isExpired && session.allows(permissions);

  static const entries = [
    MenuDestination(
      AppRoutes.home,
      'menu.home',
      Icons.home_outlined,
      available: true,
    ),
    MenuDestination(
      AppRoutes.notifications,
      'menu.notifications',
      Icons.notifications_outlined,
      permissions: ['@communication:post:manage'],
      available: true,
      hideWithoutPermission: true,
    ),
    MenuDestination(
      AppRoutes.residents,
      'menu.residents',
      Icons.people_outline,
      available: true,
      permissions: ['@core:user:manage'],
    ),
    MenuDestination(
      AppRoutes.reservations,
      'menu.reservations',
      Icons.event_available_outlined,
      available: true,
      permissions: [
        '@reservation:create',
        '@reservation:view:residency',
        '@reservation:view:building',
      ],
    ),
    MenuDestination(
      AppRoutes.packages,
      'menu.packages',
      Icons.inventory_2_outlined,
      available: true,
      permissions: [
        '@delivery:create',
        '@delivery:view:building',
        '@delivery:view:residency',
      ],
    ),
    MenuDestination(
      AppRoutes.visitorAccess,
      'menu.visitorAccess',
      Icons.shield_outlined,
      available: true,
      permissions: ['@visitor:view', '@visitor:create'],
    ),
    MenuDestination(
      AppRoutes.settings,
      'menu.settings',
      Icons.settings_outlined,
      available: true,
    ),
    MenuDestination(
      AppRoutes.complaints,
      'menu.complaints',
      Icons.chat_bubble_outline,
      available: true,
      permissions: [
        '@complaint:create',
        '@complaint:view:residency',
        '@complaint:view:building',
        '@complaint:update:status',
        '@complaint:respond:residency',
        '@complaint:respond:building',
      ],
    ),
  ];
}
