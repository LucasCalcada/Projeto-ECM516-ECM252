import 'package:flutter/material.dart';

import '../../helpers/communication_service.dart';
import '../../helpers/core_service.dart';
import '../../lang/app_localizations.dart';
import '../../types/api_failure.dart';
import '../../types/residency_group.dart';
import '../../types/user_session.dart';
import '../shared/request_feedback.dart';
import 'residency_picker.dart';

enum NotificationAudience { building, residencies }

class NotificationCreateForm extends StatefulWidget {
  const NotificationCreateForm({
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

  @override
  State<NotificationCreateForm> createState() => _NotificationCreateFormState();
}

class _NotificationCreateFormState extends State<NotificationCreateForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  DateTime? _eventAt;
  NotificationAudience _audience = NotificationAudience.building;
  Set<String> _residencyIds = {};
  List<ResidencyGroup>? _groups;
  ApiFailure? _groupsError;
  bool _loadingGroups = false;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _handleFailure(Object error) {
    final failure = error is ApiException
        ? error.failure
        : ApiFailure.unexpected;
    if (failure == ApiFailure.unauthorized) {
      widget.onSessionExpired();
      return;
    }
    _notify(AppLocalizations.of(context).error(failure));
  }

  /// Replaces the visible message so feedback is not queued behind an old one.
  void _notify(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadGroups() async {
    if (_loadingGroups) return;
    setState(() {
      _loadingGroups = true;
      _groupsError = null;
    });
    try {
      final groups = await widget.coreService.listResidencies(widget.session);
      if (mounted) setState(() => _groups = groups);
    } catch (error) {
      if (!mounted) return;
      final failure = error is ApiException
          ? error.failure
          : ApiFailure.unexpected;
      if (failure == ApiFailure.unauthorized) {
        widget.onSessionExpired();
      } else {
        setState(() => _groupsError = failure);
      }
    } finally {
      if (mounted) setState(() => _loadingGroups = false);
    }
  }

  void _selectAudience(NotificationAudience audience) {
    setState(() => _audience = audience);
    if (audience == NotificationAudience.residencies && _groups == null) {
      _loadGroups();
    }
  }

  Future<void> _pickEventAt() async {
    final now = DateTime.now();
    final initial = _eventAt ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _eventAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    final strings = AppLocalizations.of(context);
    if (_submitting || !_formKey.currentState!.validate()) return;
    final toResidencies = _audience == NotificationAudience.residencies;
    if (toResidencies && _residencyIds.isEmpty) {
      _notify(strings.text('notifications.form.residenciesRequired'));
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.service.createPost(
        widget.session,
        title: _title.text.trim(),
        description: _description.text.trim(),
        eventAt: _eventAt,
        residencyIds: toResidencies ? _residencyIds.toList() : const [],
      );
      if (!mounted) return;
      _formKey.currentState!.reset();
      _title.clear();
      _description.clear();
      setState(() {
        _eventAt = null;
        _residencyIds = {};
      });
      _notify(strings.text('notifications.form.sent'));
    } catch (error) {
      if (mounted) _handleFailure(error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _required(String? value) => (value ?? '').trim().isEmpty
      ? AppLocalizations.of(context).text('notifications.form.required')
      : null;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final eventAt = _eventAt;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextFormField(
            key: const Key('notification-title'),
            controller: _title,
            enabled: !_submitting,
            maxLength: 160,
            textInputAction: TextInputAction.next,
            validator: _required,
            decoration: InputDecoration(
              labelText: strings.text('notifications.form.title'),
              hintText: strings.text('notifications.form.titleHint'),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('notification-description'),
            controller: _description,
            enabled: !_submitting,
            minLines: 4,
            maxLines: 8,
            validator: _required,
            decoration: InputDecoration(
              labelText: strings.text('notifications.form.description'),
              hintText: strings.text('notifications.form.descriptionHint'),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            strings.text('notifications.form.eventAt'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            strings.text('notifications.form.eventAtHint'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                key: const Key('pick-event-at'),
                onPressed: _submitting ? null : _pickEventAt,
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  eventAt == null
                      ? strings.text('notifications.form.pickEventAt')
                      : '${material.formatMediumDate(eventAt)} · '
                            '${material.formatTimeOfDay(TimeOfDay.fromDateTime(eventAt), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}',
                ),
              ),
              if (eventAt != null)
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _eventAt = null),
                  child: Text(strings.text('notifications.form.clearEventAt')),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            strings.text('notifications.form.audience'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<NotificationAudience>(
            key: const Key('notification-audience'),
            segments: [
              ButtonSegment(
                value: NotificationAudience.building,
                icon: const Icon(Icons.apartment_outlined),
                label: Text(strings.text('notifications.audience.building')),
              ),
              ButtonSegment(
                value: NotificationAudience.residencies,
                icon: const Icon(Icons.home_outlined),
                label: Text(strings.text('notifications.audience.residencies')),
              ),
            ],
            selected: {_audience},
            onSelectionChanged: _submitting
                ? null
                : (selection) => _selectAudience(selection.single),
          ),
          if (_audience == NotificationAudience.residencies) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(strings.text('notifications.form.residencies')),
                ),
                Text(
                  strings.format('notifications.form.selected', {
                    'count': '${_residencyIds.length}',
                  }),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loadingGroups) const LinearProgressIndicator(),
            if (_groupsError != null)
              RequestFeedback(failure: _groupsError, onRetry: _loadGroups),
            if (_groups != null)
              ResidencyPicker(
                groups: _groups!,
                selected: _residencyIds,
                enabled: !_submitting,
                onChanged: (ids) => setState(() => _residencyIds = ids),
              ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            key: const Key('submit-notification'),
            onPressed: _submitting ? null : _submit,
            icon: const Icon(Icons.send_outlined),
            label: Text(
              strings.text(
                _submitting
                    ? 'notifications.form.submitting'
                    : 'notifications.form.submit',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
