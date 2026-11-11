import 'package:flutter/material.dart';

import '../../helpers/visitor_service.dart';
import '../../helpers/visitor_entry_datetime.dart';
import '../../lang/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../types/api_failure.dart';
import '../../types/user_session.dart';

class VisitorAccessForm extends StatefulWidget {
  const VisitorAccessForm({
    super.key,
    required this.session,
    required this.service,
    required this.onSessionExpired,
  });

  final UserSession session;
  final VisitorService service;
  final VoidCallback onSessionExpired;

  @override
  State<VisitorAccessForm> createState() => _VisitorAccessFormState();
}

class _VisitorAccessFormState extends State<VisitorAccessForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cpf = TextEditingController();
  final _rg = TextEditingController();
  final _entry = TextEditingController();
  final _nameFocus = FocusNode();
  final _cpfFocus = FocusNode();
  final _rgFocus = FocusNode();
  final _entryFocus = FocusNode();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _cpf.dispose();
    _rg.dispose();
    _entry.dispose();
    _nameFocus.dispose();
    _cpfFocus.dispose();
    _rgFocus.dispose();
    _entryFocus.dispose();
    super.dispose();
  }

  String? _required(String? value, String message) =>
      value == null || value.trim().isEmpty ? message : null;

  Future<void> _submit() async {
    if (_submitting) return;
    final strings = AppLocalizations.of(context);
    final valid = _formKey.currentState!.validate();
    if (!valid) {
      if (_name.text.trim().isEmpty) {
        _nameFocus.requestFocus();
      } else if (_cpf.text.trim().isEmpty) {
        _cpfFocus.requestFocus();
      } else if (_rg.text.trim().isEmpty) {
        _rgFocus.requestFocus();
      } else {
        _entryFocus.requestFocus();
      }
      return;
    }
    final name = _name.text.trim();
    final cpf = _cpf.text.trim();
    final rg = _rg.text.trim();
    final entryAt = parseVisitorEntryDateTime(_entry.text);
    setState(() => _submitting = true);
    try {
      await widget.service.register(
        widget.session,
        name: name,
        cpf: cpf,
        rg: rg,
        entryAt: entryAt,
      );
      if (!mounted) return;
      _name.clear();
      _cpf.clear();
      _rg.clear();
      _entry.clear();
      _notify(strings.text('visitorAccess.form.success'));
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.failure == ApiFailure.unauthorized) {
        widget.onSessionExpired();
        return;
      }
      _notify(strings.text('visitorAccess.form.createError'));
    } catch (_) {
      if (!mounted) return;
      _notify(strings.text('visitorAccess.form.createError'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: HiveColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fields = [
                _field(
                  key: const Key('visitor-name'),
                  label: strings.text('visitorAccess.form.name'),
                  controller: _name,
                  focus: _nameFocus,
                  hint: strings.text('visitorAccess.form.namePlaceholder'),
                  error: strings.text('visitorAccess.form.nameError'),
                  textInputAction: TextInputAction.next,
                ),
                _field(
                  key: const Key('visitor-cpf'),
                  label: strings.text('visitorAccess.form.cpf'),
                  controller: _cpf,
                  focus: _cpfFocus,
                  hint: strings.text('visitorAccess.form.cpfPlaceholder'),
                  error: strings.text('visitorAccess.form.cpfError'),
                  textInputAction: TextInputAction.next,
                ),
                _field(
                  key: const Key('visitor-rg'),
                  label: strings.text('visitorAccess.form.rg'),
                  controller: _rg,
                  focus: _rgFocus,
                  hint: strings.text('visitorAccess.form.rgPlaceholder'),
                  error: strings.text('visitorAccess.form.rgError'),
                  textInputAction: TextInputAction.next,
                ),
                _field(
                  key: const Key('visitor-entry'),
                  label: strings.text('visitorAccess.form.dateTime'),
                  controller: _entry,
                  focus: _entryFocus,
                  hint: strings.text('visitorAccess.form.dateTimePlaceholder'),
                  helper: strings.text('visitorAccess.form.dateTimeHelp'),
                  validator: (value) =>
                      value == null ||
                          value.trim().isEmpty ||
                          parseVisitorEntryDateTime(value) != null
                      ? null
                      : strings.text('visitorAccess.form.dateTimeError'),
                  textInputAction: TextInputAction.done,
                ),
              ];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._rows(fields, constraints.maxWidth >= 768),
                  FilledButton(
                    key: const Key('visitor-submit'),
                    onPressed: _submitting ? null : _submit,
                    child: Text(
                      _submitting
                          ? strings.text('visitorAccess.form.submitting')
                          : strings.text('visitorAccess.form.submit'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _rows(List<Widget> fields, bool wide) {
    if (!wide) {
      return [
        for (final field in fields) ...[field, const SizedBox(height: 12)],
      ];
    }
    final rows = <Widget>[];
    for (var index = 0; index < fields.length; index += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: fields[index]),
              const SizedBox(width: 12),
              Expanded(
                child: index + 1 < fields.length
                    ? fields[index + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  Widget _field({
    required Key key,
    required String label,
    required TextEditingController controller,
    FocusNode? focus,
    String? hint,
    String? error,
    String? helper,
    FormFieldValidator<String>? validator,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: HiveColors.body, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 4),
        TextFormField(
          key: key,
          controller: controller,
          focusNode: focus,
          enabled: !_submitting,
          autovalidateMode: validator != null
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            helperMaxLines: 3,
            errorMaxLines: 3,
          ),
          style: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            color: HiveColors.text,
          ),
          validator:
              validator ??
              (value) {
                final message = error;
                if (message == null) return null;
                return _required(value, message);
              },
        ),
      ],
    );
  }
}
