import 'package:flutter/material.dart';
import '../../helpers/reservation_service.dart';
import '../../lang/app_localizations.dart';
import '../../types/api_failure.dart';
import '../../types/reservation.dart';
import '../../types/user_session.dart';
import '../shared/request_feedback.dart';
import 'reservation_area_selector.dart';
import 'reservation_calendar.dart';

class ReservationCreatePanel extends StatefulWidget {
  const ReservationCreatePanel({super.key, required this.session, required this.service, required this.onSessionExpired});
  final UserSession session;
  final ReservationService service;
  final VoidCallback onSessionExpired;
  @override
  State<ReservationCreatePanel> createState() => ReservationCreatePanelState();
}

class ReservationCreatePanelState extends State<ReservationCreatePanel> {
  List<ReservationCommonArea> _areas = [];
  List<Reservation> _reservations = [];
  ReservationCommonArea? _area;
  DateTime? _date;
  bool _loadingAreas = true;
  bool _loadingCalendar = false;
  bool _submitting = false;
  ApiFailure? _areasError;
  ApiFailure? _calendarError;
  String? _feedbackKey;
  int _read = 0;
  bool _confirming = false;

  @override
  void initState() { super.initState(); _loadAreas(); }

  ApiFailure _failure(Object error) => error is ApiException ? error.failure : ApiFailure.unexpected;
  bool _expired(Object error) {
    if (_failure(error) != ApiFailure.unauthorized) return false;
    widget.onSessionExpired();
    return true;
  }

  Future<void> _loadAreas() async {
    setState(() { _loadingAreas = true; _areasError = null; });
    try {
      final areas = await widget.service.commonAreas(widget.session);
      if (!mounted) return;
      setState(() { _areas = areas; _area = areas.isEmpty ? null : areas.first; _date = null; });
      if (_area != null) await _loadCalendar();
    } catch (error) {
      if (mounted && !_expired(error)) setState(() => _areasError = _failure(error));
    } finally {
      if (mounted) setState(() => _loadingAreas = false);
    }
  }

  Future<void> _loadCalendar() async {
    final area = _area;
    if (area == null) return;
    final read = ++_read;
    setState(() { _loadingCalendar = true; _calendarError = null; });
    try {
      final reservations = await widget.service.forArea(widget.session, area.id);
      if (!mounted || read != _read) return;
      setState(() => _reservations = reservations);
    } catch (error) {
      if (mounted && read == _read && !_expired(error)) setState(() => _calendarError = _failure(error));
    } finally {
      if (mounted && read == _read) setState(() => _loadingCalendar = false);
    }
  }

  Future<bool> beforeLeave() async {
    if (_submitting || _confirming) return false;
    if (_date == null) return true;
    _confirming = true;
    final strings = AppLocalizations.of(context);
    final discard = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(strings.text('reservations.discard.title')),
      content: Text(strings.text('reservations.discard.message')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.text('reservations.discard.keep'))),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(strings.text('reservations.discard.confirm'))),
      ],
    ));
    _confirming = false;
    if (!mounted) return false;
    if (discard == true) setState(() => _date = null);
    return discard == true;
  }

  Future<void> _changeArea(String id) async {
    if (_submitting || id == _area?.id || !await beforeLeave() || !mounted) return;
    setState(() {
      _area = _areas.firstWhere((area) => area.id == id);
      _date = null;
      _reservations = [];
      _feedbackKey = null;
    });
    await _loadCalendar();
  }

  Future<void> _submit() async {
    if (_submitting || _loadingAreas || _loadingCalendar || _calendarError != null) return;
    final date = _date;
    final area = _area;
    if (date == null || area == null) {
      setState(() => _feedbackKey = 'reservations.missingDate');
      return;
    }
    if (date.isBefore(reservationToday()) || _reservations.any((item) => reservationDateString(item.date) == reservationDateString(date))) {
      setState(() => _feedbackKey = 'reservations.unavailableDate');
      return;
    }
    setState(() { _submitting = true; _feedbackKey = null; });
    try {
      final reservation = await widget.service.create(widget.session, area, date);
      if (!mounted) return;
      setState(() { _reservations = [..._reservations, reservation]; _date = null; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).text('reservations.success')), duration: const Duration(seconds: 5)));
    } catch (error) {
      if (!mounted || _expired(error)) return;
      if (error is ApiException && error.statusCode == 409) {
        setState(() => _feedbackKey = 'reservations.conflict');
        await _loadCalendar();
      } else {
        setState(() => _feedbackKey = 'reservations.createError');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final busy = _submitting || _loadingCalendar || _loadingAreas;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_loadingAreas) const LinearProgressIndicator(),
      if (_areasError != null) RequestFeedback(failure: _areasError, onRetry: _loadAreas),
      if (!_loadingAreas && _areasError == null && _areas.isEmpty) RequestFeedback(message: strings.text('reservations.noAreas')),
      if (_areas.isNotEmpty) ...[
        ReservationAreaSelector(areas: _areas, selectedId: _area?.id, enabled: !_submitting, onChanged: _changeArea),
        const SizedBox(height: 8),
        Text(_date == null ? strings.text('reservations.selectDate') : '${strings.text('reservations.selectedDate')}: ${MaterialLocalizations.of(context).formatMediumDate(_date!)}'),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: FilledButton.icon(
          key: const Key('reservation-submit'), onPressed: busy || _calendarError != null ? null : _submit,
          icon: const Icon(Icons.event_available_outlined, size: 16),
          label: Text(strings.text(_submitting ? 'reservations.submitting' : 'reservations.confirm')),
        )),
        if (_feedbackKey != null) Semantics(liveRegion: true, child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12), child: Text(strings.text(_feedbackKey!), style: TextStyle(color: Theme.of(context).colorScheme.error)),
        )),
        Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(strings.text('reservations.calendar.title'), style: Theme.of(context).textTheme.titleLarge),
          TextButton.icon(
            key: const Key('reservation-calendar-refresh'),
            onPressed: busy ? null : _loadCalendar,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(strings.text('refresh')),
          ),
        ]),
        if (_loadingCalendar) const LinearProgressIndicator(),
        if (_calendarError != null) RequestFeedback(failure: _calendarError, onRetry: _loadCalendar),
        ReservationCalendar(
          reservations: _reservations, selectedDate: _date, enabled: !busy && _calendarError == null,
          onSelect: (date) => setState(() { _date = date; _feedbackKey = null; }),
        ),
      ],
    ]);
  }
}
