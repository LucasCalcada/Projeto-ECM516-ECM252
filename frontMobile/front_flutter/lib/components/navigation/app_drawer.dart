import 'package:flutter/material.dart';

import '../../lang/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../routes/menu_destination.dart';
import '../../types/user_session.dart';
import 'building_header.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.session,
    required this.currentRoute,
    required this.onNavigate,
    required this.onSignOut,
    required this.signingOut,
  });

  final UserSession session;
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final VoidCallback onSignOut;
  final bool signingOut;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    Widget entry(MenuDestination destination) {
      final allowed = session.allows(destination.permissions);
      final explanation = !allowed
          ? strings.text('menu.noPermission')
          : !destination.available
          ? strings.text('menu.comingSoon')
          : null;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: ListTile(
          key: ValueKey('menu-${destination.route}'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          selectedTileColor: Theme.of(context).colorScheme.primary
              .withValues(alpha: 0.16),
          leading: Icon(destination.icon),
          title: Text(strings.text(destination.label)),
          subtitle: explanation == null ? null : Text(explanation),
          trailing: allowed ? null : const Icon(Icons.lock_outline, size: 18),
          selected: currentRoute == destination.route,
          enabled: destination.canOpen(session) && !signingOut,
          onTap: () => onNavigate(destination.route),
        ),
      );
    }

    return Drawer(
      child: SafeArea(
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
                      BuildingHeader(session: session),
                      const Divider(),
                      for (final destination in MenuDestination.entries)
                        if (destination.route != AppRoutes.settings)
                          entry(destination),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 16),
                    child: Column(
                      children: [
                        const Divider(),
                        entry(MenuDestination.entries.last),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: ListTile(
                            key: const Key('menu-sign-out'),
                            leading: const Icon(Icons.logout),
                            title: Text(
                              strings.text(
                                signingOut ? 'signingOut' : 'signOut',
                              ),
                            ),
                            enabled: !signingOut,
                            onTap: onSignOut,
                          ),
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
