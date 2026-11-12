import 'package:flutter/material.dart';

import '../components/residents/resident_editor.dart';
import '../components/residents/resident_row.dart';
import '../components/residents/residents_branch.dart';
import '../components/shared/request_feedback.dart';
import '../helpers/residents_service.dart';
import '../lang/app_localizations.dart';
import '../theme/app_theme.dart';
import '../types/api_failure.dart';
import '../types/resident.dart';
import '../types/user_session.dart';

class ResidentsView extends StatefulWidget {
  const ResidentsView({super.key, required this.session, required this.service, required this.onSessionExpired});
  final UserSession session;
  final ResidentsService service;
  final VoidCallback onSessionExpired;

  @override
  State<ResidentsView> createState() => _ResidentsViewState();
}

class _ResidentsViewState extends State<ResidentsView> {
  List<ResidentGroup>? _groups;
  final _updatedResidents = <String, Resident>{};
  ApiFailure? _error;
  bool _loading = false;
  bool _editing = false;
  bool _saved = false;
  int _revision = 0;
  bool get _allowed => widget.session.allows(['@core:user:manage']);

  @override
  void initState() {
    super.initState();
    if (_allowed) _load();
  }

  Future<void> _load() async {
    if (_loading || !_allowed) return;
    setState(() { _loading = true; _error = null; _saved = false; });
    try {
      final groups = await widget.service.groups(widget.session);
      if (!mounted) return;
      setState(() { _groups = groups; _updatedResidents.clear(); _revision++; });
    } catch (error) {
      if (!mounted) return;
      final failure = error is ApiException ? error.failure : ApiFailure.unexpected;
      if (failure == ApiFailure.unauthorized) {
        widget.onSessionExpired();
      } else {
        setState(() => _error = failure);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(Resident resident) async {
    if (_editing) return;
    setState(() { _editing = true; _saved = false; });
    final saved = await showDialog<Resident>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: .6),
      builder: (context) => ResidentEditor(userId: resident.id, session: widget.session, service: widget.service, onSessionExpired: widget.onSessionExpired),
    );
    if (!mounted) return;
    setState(() {
      _editing = false;
      if (saved != null) { _updatedResidents[saved.id] = saved; _saved = true; }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (!_allowed) return Center(child: Text(strings.text('residents.accessDenied')));
    return LayoutBuilder(builder: (context, constraints) => ListView(
      key: const PageStorageKey('residents-scroll'),
      padding: EdgeInsets.all(constraints.maxWidth >= 768 ? 32 : 16),
      children: [
        Row(children: [
          const Icon(Icons.people_outline, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(strings.text('residents.title'), style: Theme.of(context).textTheme.headlineSmall)),
        ]),
        const SizedBox(height: 8),
        Text(widget.session.buildingName, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(
          key: const Key('residents-refresh'),
          onPressed: _loading || _editing ? null : _load,
          icon: const Icon(Icons.refresh),
          label: Text(strings.text('refresh')),
        )),
        const SizedBox(height: 16),
        if (_loading) Semantics(label: strings.text('residents.loading'), child: const LinearProgressIndicator()),
        if (_error != null) RequestFeedback(failure: _error, onRetry: _load),
        if (_saved) Padding(padding: const EdgeInsets.only(bottom: 16), child: Semantics(liveRegion: true, child: Text(strings.text('residents.saved')))),
        if (_groups != null && _groups!.isEmpty) RequestFeedback(message: strings.text('residents.noGroups')),
        if (_groups != null) for (final group in _groups!)
          Padding(
            key: ValueKey('resident-group-container-${group.id}'),
            padding: const EdgeInsets.only(bottom: 12),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: HiveColors.canvas, borderRadius: BorderRadius.all(Radius.circular(8))),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ResidentsBranch<ResidentResidency>(
                  key: ValueKey('group-${group.id}-$_revision'),
                  nodeKey: 'residents-group-${group.id}',
                  label: group.name.isEmpty ? strings.text('residents.unnamedGroup') : group.name,
                  load: () => widget.service.residencies(widget.session, group.id),
                  emptyMessage: strings.text('residents.noResidencies'),
                  onSessionExpired: widget.onSessionExpired,
                  itemBuilder: (residency) => ResidentsBranch<Resident>(
                    key: ValueKey(residency.id),
                    nodeKey: 'residents-residency-${residency.id}',
                    label: residency.name.isNotEmpty ? residency.name : residency.code.isNotEmpty ? residency.code : strings.text('residents.unnamedResidency'),
                    load: () => widget.service.residents(widget.session, residency.id),
                    emptyMessage: strings.text('residents.noResidents'),
                    onSessionExpired: widget.onSessionExpired,
                    itemBuilder: (resident) => ResidentRow(
                      key: ValueKey(resident.id),
                      resident: _updatedResidents[resident.id] ?? resident,
                      onEdit: () => _edit(_updatedResidents[resident.id] ?? resident),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ));
  }
}
