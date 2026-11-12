import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../helpers/residents_service.dart';
import '../../lang/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../types/api_failure.dart';
import '../../types/resident.dart';
import '../../types/user_session.dart';
import '../shared/request_feedback.dart';

class ResidentEditor extends StatefulWidget {
  const ResidentEditor({super.key, required this.userId, required this.session, required this.service, required this.onSessionExpired});
  final String userId;
  final UserSession session;
  final ResidentsService service;
  final VoidCallback onSessionExpired;

  @override
  State<ResidentEditor> createState() => _ResidentEditorState();
}

class _ResidentEditorState extends State<ResidentEditor> {
  final _name = TextEditingController();
  final _permission = TextEditingController();
  final _nameFocus = FocusNode();
  final _form = GlobalKey<FormState>();
  Resident? _original;
  List<String> _permissions = [];
  ApiFailure? _error;
  bool _missing = false;
  bool _loading = true;
  bool _saving = false;
  bool _confirming = false;

  bool get _self => widget.userId == widget.session.userId;
  bool get _dirty => _original != null && (
    _name.text != _original!.name ||
    (!_self && (!listEquals(_permissions, _original!.permissions) || _permission.text.trim().isNotEmpty))
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _permission.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _fail(Object error) {
    final failure = error is ApiException ? error.failure : ApiFailure.unexpected;
    if (failure == ApiFailure.unauthorized) {
      Navigator.of(context).pop();
      widget.onSessionExpired();
      return;
    }
    setState(() {
      _error = failure;
      _missing = error is ApiException && error.statusCode == 404;
    });
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _missing = false; });
    try {
      final resident = await widget.service.detail(widget.session, widget.userId);
      if (!mounted) return;
      setState(() {
        _original = resident;
        _name.text = resident.name;
        _permissions = List.of(resident.permissions);
      });
    } catch (error) {
      if (mounted) _fail(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addPermission() {
    final value = _permission.text.trim();
    if (_saving || _self || value.isEmpty) return;
    setState(() {
      if (!_permissions.contains(value)) _permissions.add(value);
      _permission.clear();
    });
  }

  Future<void> _close() async {
    if (_saving || _confirming) return;
    if (_dirty) {
      _confirming = true;
      final strings = AppLocalizations.of(context);
      final discard = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: .6),
        builder: (context) => AlertDialog(
          title: Text(strings.text('residents.discardTitle')),
          content: Text(strings.text('residents.discardMessage')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.text('residents.keepEditing'))),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(strings.text('residents.discard'))),
          ],
        ),
      );
      _confirming = false;
      if (!mounted || discard != true) return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (_saving || _original == null) return;
    if (!_form.currentState!.validate()) {
      _nameFocus.requestFocus();
      return;
    }
    // Include an entered permission even if Add was not pressed before Save.
    final permissions = [..._permissions, if (!_self) _permission.text]
        .map((value) => value.trim()).where((value) => value.isNotEmpty).toSet().toList();
    setState(() { _saving = true; _error = null; _missing = false; });
    try {
      final saved = await widget.service.update(widget.session, widget.userId, name: _name.text, permissions: permissions);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (error) {
      if (mounted) _fail(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      child: PopScope<Resident>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: AlertDialog(
        insetPadding: const EdgeInsets.all(16),
        title: Row(children: [
          Expanded(child: Text(strings.text('residents.editTitle'))),
          IconButton(key: const Key('resident-close'), tooltip: strings.text('residents.close'), onPressed: _saving ? null : _close, icon: const Icon(Icons.close)),
        ]),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              if (_loading) Semantics(label: strings.text('residents.loading'), child: const LinearProgressIndicator()),
              if (_error != null)
                _missing
                    ? RequestFeedback(message: strings.text('residents.notFound'))
                    : RequestFeedback(failure: _error, onRetry: _original == null && !_loading ? _load : null),
              if (_original != null)
                Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(strings.text('residents.name'), style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('resident-name'),
                    controller: _name,
                    focusNode: _nameFocus,
                    autofocus: true,
                    enabled: !_saving,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(hintText: strings.text('residents.namePlaceholder')),
                    validator: (value) => value == null || value.trim().isEmpty ? strings.text('residents.nameRequired') : null,
                  ),
                  const SizedBox(height: 24),
                  Text(strings.text('residents.permissions'), style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  if (_self) Text(strings.text('residents.selfPermissionsHelp'), style: Theme.of(context).textTheme.bodyMedium),
                  if (!_self) ...[
                    TextFormField(
                      key: const Key('resident-permission-input'),
                      controller: _permission,
                      enabled: !_saving,
                      decoration: InputDecoration(hintText: '@core:user:manage', helperText: strings.text('residents.permissionsHelp'), helperMaxLines: 4),
                      onFieldSubmitted: (_) => _addPermission(),
                    ),
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: TextButton.icon(
                      key: const Key('resident-add-permission'),
                      onPressed: _saving ? null : _addPermission,
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(strings.text('residents.addPermission')),
                    )),
                  ],
                  if (_permissions.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(strings.text('residents.noPermissions'), style: Theme.of(context).textTheme.bodySmall)),
                  for (final permission in _permissions)
                    Row(children: [
                      Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(permission, style: const TextStyle(fontSize: 14, color: HiveColors.body)))),
                      if (!_self) IconButton(
                        tooltip: '${strings.text('residents.removePermission')}: $permission',
                        onPressed: _saving ? null : () => setState(() => _permissions.remove(permission)),
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                      ),
                    ]),
                ])),
            ]),
          ),
        ),
        actions: [
          TextButton(key: const Key('resident-cancel'), onPressed: _saving ? null : _close, child: Text(strings.text('residents.cancel'))),
          if (_original != null) FilledButton(
            key: const Key('resident-save'),
            onPressed: _saving || _loading ? null : _save,
            child: Text(strings.text(_saving ? 'residents.saving' : 'residents.save')),
          ),
        ],
      ),
      ),
    );
  }
}
