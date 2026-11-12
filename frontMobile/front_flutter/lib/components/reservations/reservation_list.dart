import 'package:flutter/material.dart';
import '../../helpers/reservation_service.dart';
import '../../lang/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../types/api_failure.dart';
import '../../types/reservation.dart';
import '../../types/user_session.dart';
import '../shared/request_feedback.dart';
import 'reservation_area_selector.dart';

class ReservationList extends StatefulWidget {
  const ReservationList({super.key, required this.session, required this.service, required this.building, required this.onSessionExpired});
  final UserSession session;
  final ReservationService service;
  final bool building;
  final VoidCallback onSessionExpired;
  @override
  State<ReservationList> createState() => _ReservationListState();
}

class _ReservationListState extends State<ReservationList> {
  List<ReservationCommonArea> _areas = [];
  String? _areaId;
  List<Reservation>? _items;
  bool _loading = false;
  bool _loadingAreas = false;
  ApiFailure? _error;
  ApiFailure? _areasError;
  int _read = 0;

  @override
  void initState() {
    super.initState();
    if (widget.building) {
      _loadAreas();
    } else {
      _load();
    }
  }

  ApiFailure _failure(Object error) => error is ApiException ? error.failure : ApiFailure.unexpected;
  bool _expired(Object error) {
    if (_failure(error) != ApiFailure.unauthorized) return false;
    widget.onSessionExpired();
    return true;
  }

  Future<void> _loadAreas() async {
    if (_loadingAreas) return;
    setState(() { _loadingAreas = true; _areasError = null; });
    try {
      final areas = await widget.service.commonAreas(widget.session);
      if (!mounted) return;
      setState(() { _areas = areas; _areaId = areas.isEmpty ? null : areas.first.id; });
      if (_areaId != null) await _load();
    } catch (error) {
      if (mounted && !_expired(error)) setState(() => _areasError = _failure(error));
    } finally {
      if (mounted) setState(() => _loadingAreas = false);
    }
  }

  Future<void> _load() async {
    final areaId = _areaId;
    if (widget.building && areaId == null) return;
    final read = ++_read;
    setState(() { _loading = true; _error = null; });
    try {
      final items = widget.building
          ? await widget.service.forArea(widget.session, areaId!)
          : await widget.service.forResidency(widget.session);
      if (!mounted || read != _read) return;
      items.sort((a, b) => a.date.compareTo(b.date));
      setState(() => _items = items);
    } catch (error) {
      if (mounted && read == _read && !_expired(error)) setState(() => _error = _failure(error));
    } finally {
      if (mounted && read == _read) setState(() => _loading = false);
    }
  }

  void _changeArea(String id) {
    if (id == _areaId) return;
    setState(() { _areaId = id; _items = null; });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_loadingAreas) const LinearProgressIndicator(),
      if (_areasError != null) RequestFeedback(failure: _areasError, onRetry: _loadAreas),
      if (widget.building && !_loadingAreas && _areasError == null && _areas.isEmpty)
        RequestFeedback(message: strings.text('reservations.noAreas')),
      if (widget.building && _areas.isNotEmpty) ...[
        ReservationAreaSelector(areas: _areas, selectedId: _areaId, onChanged: _changeArea),
        const SizedBox(height: 16),
      ],
      if (!widget.building || _areaId != null) ...[
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(
          key: const Key('reservation-refresh'),
          onPressed: _loading || _loadingAreas ? null : _load,
          icon: const Icon(Icons.refresh, size: 16), label: Text(strings.text('refresh')),
        )),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) RequestFeedback(failure: _error, onRetry: _load),
        if (!_loading && _error == null && _items != null && _items!.isEmpty)
          RequestFeedback(message: strings.text(widget.building ? 'reservations.emptyBuilding' : 'reservations.emptyResidency')),
        for (final reservation in _items ?? <Reservation>[])
          ReservationListItem(reservation: reservation, showResident: widget.building),
      ],
    ]);
  }
}

class ReservationListItem extends StatelessWidget {
  const ReservationListItem({super.key, required this.reservation, required this.showResident});
  final Reservation reservation;
  final bool showResident;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      key: ValueKey('reservation-${reservation.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: HiveColors.canvas, borderRadius: BorderRadius.all(Radius.circular(8))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(reservation.commonAreaName, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(MaterialLocalizations.of(context).formatMediumDate(reservation.date)),
        const SizedBox(height: 4),
        Text(strings.text('reservations.allDay'), style: Theme.of(context).textTheme.bodySmall),
        if (showResident) ...[
          const SizedBox(height: 8),
          Text('${strings.text('reservations.resident')}: ${reservation.residentName}', style: Theme.of(context).textTheme.bodySmall),
        ],
      ]),
    );
  }
}
