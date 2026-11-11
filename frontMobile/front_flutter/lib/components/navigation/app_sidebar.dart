import 'package:flutter/material.dart';

import '../../lang/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../routes/menu_destination.dart';
import '../../theme/app_theme.dart';
import '../../types/user_session.dart';
import 'building_header.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.session,
    required this.currentRoute,
    required this.expanded,
    required this.onNavigate,
    required this.onSignOut,
    required this.signingOut,
    required this.busy,
  });

  final UserSession session;
  final String currentRoute;
  final bool expanded;
  final ValueChanged<String> onNavigate;
  final VoidCallback onSignOut;
  final bool signingOut;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    Widget item({
      required Key key,
      required IconData icon,
      required String label,
      required bool enabled,
      required VoidCallback onTap,
      String? explanation,
      bool selected = false,
    }) {
      final description = explanation == null ? label : '$label. $explanation';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Tooltip(
          message: description,
          excludeFromSemantics: true,
          child: Semantics(
            key: key,
            label: description,
            button: true,
            enabled: enabled,
            selected: selected,
            onTap: enabled ? onTap : null,
            excludeSemantics: true,
            child: TextButton(
              onPressed: enabled ? onTap : null,
              style: ButtonStyle(
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(
                    horizontal: expanded ? 12 : 0,
                    vertical: 6,
                  ),
                ),
                backgroundColor: WidgetStatePropertyAll(
                  selected
                      ? colors.primary.withValues(alpha: 0.16)
                      : Colors.transparent,
                ),
                foregroundColor: WidgetStatePropertyAll(
                  !enabled
                      ? colors.onSurfaceVariant
                      : selected
                      ? colors.primary
                      : colors.onSurface,
                ),
              ),
              child: expanded
                  ? Row(
                      children: [
                        Icon(icon, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label),
                              if (explanation != null)
                                Text(
                                  explanation,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Icon(icon, size: 24),
            ),
          ),
        ),
      );
    }

    Widget entry(MenuDestination destination) {
      final allowed = session.allows(destination.permissions);
      return item(
        key: ValueKey('menu-${destination.route}'),
        icon: destination.icon,
        label: strings.text(destination.label),
        explanation: !allowed
            ? strings.text('menu.noPermission')
            : !destination.available
            ? strings.text('menu.comingSoon')
            : null,
        selected: currentRoute == destination.route,
        enabled: destination.canOpen(session) && !busy,
        onTap: () => onNavigate(destination.route),
      );
    }

    final buildingName = session.buildingName.isEmpty
        ? strings.text('selector.unnamedBuilding')
        : session.buildingName;
    final buildingLabel = [
      buildingName,
      if (session.residencyName?.isNotEmpty == true) session.residencyName!,
    ].join(', ');

    return SizedBox(
      key: const Key('app-sidebar'),
      width: expanded ? 240 : 64,
      child: Material(
        color: HiveColors.raised,
        shape: Border(right: BorderSide(color: HiveColors.boundary.withValues(alpha: 0.35))),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (expanded)
                        BuildingHeader(session: session)
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Tooltip(
                            message: buildingLabel,
                            child: const SizedBox(
                              height: 48,
                              child: Icon(Icons.apartment_outlined, size: 28),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      for (final destination in MenuDestination.entries)
                        if (destination.route != AppRoutes.settings)
                          entry(destination),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        entry(
                          MenuDestination.entries.firstWhere(
                            (destination) =>
                                destination.route == AppRoutes.settings,
                          ),
                        ),
                        item(
                          key: const Key('menu-sign-out'),
                          icon: Icons.logout,
                          label: strings.text(
                            signingOut ? 'signingOut' : 'signOut',
                          ),
                          enabled: !busy,
                          onTap: onSignOut,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
