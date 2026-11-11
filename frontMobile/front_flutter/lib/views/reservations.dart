import 'package:flutter/material.dart';
import '../components/reservations/reservation_create_panel.dart';
import '../components/reservations/reservation_list.dart';
import '../components/reservations/reservations_header.dart';
import '../helpers/reservation_service.dart';
import '../lang/app_localizations.dart';
import '../types/user_session.dart';

/// Created once with the shell's view, so the shell can guard menu/back/logout.
class ReservationsNavigationController {
  Future<bool> Function()? _beforeLeave;
  Future<bool> onBeforeLeave() async => await _beforeLeave?.call() ?? true;
  Future<bool> onBack() async => !await onBeforeLeave();
}

List<ReservationMode> reservationModes(UserSession session) {
  if (session.isExpired) return [];
  final hasResidency = session.residencyId?.isNotEmpty == true;
  return [
    if (hasResidency && session.allows(['@reservation:create'])) ReservationMode.create,
    if (session.allows(['@reservation:view:building'])) ReservationMode.building,
    if (hasResidency && session.allows(['@reservation:view:residency'])) ReservationMode.residency,
  ];
}

class ReservationsView extends StatefulWidget {
  const ReservationsView({super.key, required this.session, required this.service, required this.onSessionExpired, required this.navigation});
  final UserSession session;
  final ReservationService service;
  final VoidCallback onSessionExpired;
  final ReservationsNavigationController navigation;
  @override
  State<ReservationsView> createState() => _ReservationsViewState();
}

class _ReservationsViewState extends State<ReservationsView> {
  final _createKey = GlobalKey<ReservationCreatePanelState>();
  ReservationMode? _mode;
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    final modes = reservationModes(widget.session);
    _mode = modes.isEmpty ? null : modes.first;
    widget.navigation._beforeLeave = _beforeLeave;
  }

  @override
  void didUpdateWidget(ReservationsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigation != widget.navigation) {
      oldWidget.navigation._beforeLeave = null;
      widget.navigation._beforeLeave = _beforeLeave;
    }
  }

  @override
  void dispose() {
    widget.navigation._beforeLeave = null;
    super.dispose();
  }

  Future<bool> _beforeLeave() async => await _createKey.currentState?.beforeLeave() ?? true;

  Future<void> _changeMode(ReservationMode next) async {
    if (_switching || next == _mode) return;
    setState(() => _switching = true);
    try {
      if (!await _beforeLeave() || !mounted) return;
      setState(() => _mode = next);
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modes = reservationModes(widget.session);
    final mode = modes.contains(_mode) ? _mode : (modes.isEmpty ? null : modes.first);
    if (mode == null) {
      return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(
        AppLocalizations.of(context).text('reservations.accessDenied'),
        style: Theme.of(context).textTheme.headlineSmall,
      )));
    }
    return LayoutBuilder(builder: (context, constraints) => ListView(
      key: ValueKey('reservations-${mode.name}'),
      padding: EdgeInsets.all(constraints.maxWidth >= 768 ? 32 : 16),
      children: [
        ReservationsHeader(mode: mode, options: modes, onModeChanged: _changeMode, busy: _switching),
        if (mode == ReservationMode.create)
          ReservationCreatePanel(key: _createKey, session: widget.session, service: widget.service, onSessionExpired: widget.onSessionExpired)
        else
          ReservationList(key: ValueKey(mode), session: widget.session, service: widget.service, building: mode == ReservationMode.building, onSessionExpired: widget.onSessionExpired),
      ],
    ));
  }
}
