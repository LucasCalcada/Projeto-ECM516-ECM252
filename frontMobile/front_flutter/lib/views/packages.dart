import 'package:flutter/material.dart';

import '../components/packages/package_create_form.dart';
import '../components/packages/package_list.dart';
import '../components/packages/package_view_mode.dart';
import '../components/packages/packages_header.dart';
import '../helpers/packages_service.dart';
import '../lang/app_localizations.dart';
import '../types/delivery_package.dart';
import '../types/user_session.dart';

/// Packages service screen. Like the React view, it decides what the user can
/// see from the permissions of the already loaded session; components run the
/// service calls. Permission strings are identical to the React app.
class PackagesView extends StatefulWidget {
  const PackagesView({
    super.key,
    required this.session,
    required this.service,
    required this.onSessionExpired,
  });

  final UserSession session;
  final PackagesService service;
  final VoidCallback onSessionExpired;

  @override
  State<PackagesView> createState() => _PackagesViewState();
}

class _PackagesViewState extends State<PackagesView> {
  PackageViewMode? _activeMode;

  bool get _hasResidency => widget.session.residencyId?.isNotEmpty == true;

  List<PackageViewOption> _availableViews() => [
    if (widget.session.allows(const ['@delivery:create']))
      const PackageViewOption(PackageViewMode.create),
    if (widget.session.allows(const ['@delivery:view:building']))
      const PackageViewOption(PackageViewMode.building),
    if (widget.session.allows(const ['@delivery:view:residency']) &&
        _hasResidency)
      const PackageViewOption(PackageViewMode.residency),
  ];

  Widget _content(PackageViewMode mode) => switch (mode) {
    PackageViewMode.create => PackageCreateForm(
      key: const ValueKey('packages-create'),
      session: widget.session,
      service: widget.service,
      onSessionExpired: widget.onSessionExpired,
    ),
    PackageViewMode.building => PackageList(
      key: const ValueKey('packages-building'),
      session: widget.session,
      service: widget.service,
      scope: PackageScope.building,
      onSessionExpired: widget.onSessionExpired,
    ),
    PackageViewMode.residency => PackageList(
      key: const ValueKey('packages-residency'),
      session: widget.session,
      service: widget.service,
      scope: PackageScope.residency,
      onSessionExpired: widget.onSessionExpired,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final options = _availableViews();
    if (options.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            AppLocalizations.of(context).text('packages.accessDenied'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      );
    }
    final current = options.any((option) => option.mode == _activeMode)
        ? _activeMode!
        : options.first.mode;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Page margin is applied once: 16 when compact, 32 from 768.
        final gutter = constraints.maxWidth < 768 ? 16.0 : 32.0;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: SingleChildScrollView(
              key: const PageStorageKey('packages-scroll'),
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PackagesHeader(
                    activeMode: current,
                    options: options,
                    onModeChange: (mode) => setState(() => _activeMode = mode),
                  ),
                  _content(current),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
