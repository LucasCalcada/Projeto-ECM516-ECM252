import 'package:flutter/material.dart';

import '../components/visitor_access/visitor_access_form.dart';
import '../components/visitor_access/visitor_access_header.dart';
import '../components/visitor_access/visitor_access_residency_list.dart';
import '../helpers/visitor_service.dart';
import '../lang/app_localizations.dart';
import '../types/user_session.dart';

const createVisitorAccessPermission = '@visitor:create';
const viewVisitorAccessPermission = '@visitor:view';

List<VisitorAccessMode> visitorAccessModes(UserSession session) {
  final modes = <VisitorAccessMode>[];
  final residencyId = session.residencyId;
  if (session.allows([createVisitorAccessPermission]) &&
      residencyId != null &&
      residencyId.isNotEmpty) {
    modes.add(VisitorAccessMode.create);
  }
  if (session.allows([viewVisitorAccessPermission])) {
    modes.add(VisitorAccessMode.view);
  }
  return modes;
}

class VisitorAccessView extends StatefulWidget {
  const VisitorAccessView({
    super.key,
    required this.session,
    required this.service,
    required this.onSessionExpired,
  });

  final UserSession session;
  final VisitorService service;
  final VoidCallback onSessionExpired;

  @override
  State<VisitorAccessView> createState() => _VisitorAccessViewState();
}

class _VisitorAccessViewState extends State<VisitorAccessView> {
  VisitorAccessMode? _mode;

  @override
  void initState() {
    super.initState();
    final modes = visitorAccessModes(widget.session);
    _mode = modes.isEmpty ? null : modes.first;
  }

  @override
  Widget build(BuildContext context) {
    final modes = visitorAccessModes(widget.session);
    final mode = modes.contains(_mode)
        ? _mode
        : (modes.isEmpty ? null : modes.first);
    if (mode == null) {
      return Center(
        child: Text(
          AppLocalizations.of(context).text('visitorAccess.accessDenied'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth >= 768 ? 32.0 : 16.0;
        return ListView(
          padding: EdgeInsets.all(padding),
          children: [
            VisitorAccessHeader(
              activeMode: mode,
              options: modes,
              onModeChange: (next) => setState(() => _mode = next),
            ),
            if (mode == VisitorAccessMode.create)
              VisitorAccessForm(
                session: widget.session,
                service: widget.service,
                onSessionExpired: widget.onSessionExpired,
              )
            else
              VisitorAccessResidencyList(
                session: widget.session,
                service: widget.service,
                onSessionExpired: widget.onSessionExpired,
              ),
          ],
        );
      },
    );
  }
}
