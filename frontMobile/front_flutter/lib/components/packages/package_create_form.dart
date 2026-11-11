import 'package:flutter/material.dart';

import '../../helpers/packages_service.dart';
import '../../lang/app_localizations.dart';
import '../../types/api_failure.dart';
import '../../types/delivery_package.dart';
import '../../types/user_session.dart';
import '../shared/request_feedback.dart';

/// Registers a package for a residency of the active building.
class PackageCreateForm extends StatefulWidget {
  const PackageCreateForm({
    super.key,
    required this.session,
    required this.service,
    required this.onSessionExpired,
  });

  final UserSession session;
  final PackagesService service;
  final VoidCallback onSessionExpired;

  @override
  State<PackageCreateForm> createState() => _PackageCreateFormState();
}

class _PackageCreateFormState extends State<PackageCreateForm> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  List<ResidencyOption> _residencies = const [];
  String? _selectedResidencyId;
  bool _loadingResidencies = false;
  bool _submitting = false;
  bool _validate = false;
  ApiFailure? _loadFailure;

  bool get _hasBuilding => widget.session.buildingId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadResidencies();
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  ApiFailure _failureOf(Object error) =>
      error is ApiException ? error.failure : ApiFailure.unexpected;

  Future<void> _loadResidencies() async {
    if (_loadingResidencies || !_hasBuilding) return;
    setState(() {
      _loadingResidencies = true;
      _loadFailure = null;
    });
    try {
      final loaded = await widget.service.listResidencies(widget.session);
      if (!mounted) return;
      final sorted = [...loaded]..sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        _residencies = sorted;
        // Keep a valid selection across refreshes; otherwise pick the first.
        if (!sorted.any((item) => item.id == _selectedResidencyId)) {
          _selectedResidencyId = sorted.isEmpty ? null : sorted.first.id;
        }
      });
    } catch (error) {
      if (!mounted) return;
      final failure = _failureOf(error);
      if (failure == ApiFailure.unauthorized) {
        widget.onSessionExpired();
      } else {
        setState(() => _loadFailure = failure);
      }
    } finally {
      if (mounted) setState(() => _loadingResidencies = false);
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _validate = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final strings = AppLocalizations.of(context);
    setState(() => _submitting = true);
    try {
      await widget.service.createPackage(
        widget.session,
        residencyId: _selectedResidencyId!,
        description: _description.text.trim(),
      );
      if (!mounted) return;
      // Success is only shown after the service confirms the registration.
      _description.clear();
      setState(() => _validate = false);
      _notify(strings.text('packages.form.toast.successMessage'));
    } catch (error) {
      if (!mounted) return;
      final failure = _failureOf(error);
      if (failure == ApiFailure.unauthorized) {
        widget.onSessionExpired();
      } else {
        // The draft stays in place so it can be sent again by the user.
        _notify(strings.text('packages.form.toast.createError'));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (!_hasBuilding) {
      return RequestFeedback(
        message: strings.text('packages.form.toast.missingBuilding'),
      );
    }
    final canSubmit =
        !_submitting && !_loadingResidencies && _residencies.isNotEmpty;

    final residencyField = DropdownButtonFormField<String>(
      key: ValueKey(
        'packages-residency-${_residencies.map((item) => item.id).join(',')}',
      ),
      initialValue: _selectedResidencyId,
      isExpanded: true,
      decoration: InputDecoration(labelText: strings.text('packages.residency')),
      hint: Text(strings.text('packages.form.noResidencies')),
      items: [
        for (final residency in _residencies)
          DropdownMenuItem(value: residency.id, child: Text(residency.name)),
      ],
      onChanged: _loadingResidencies || _submitting || _residencies.isEmpty
          ? null
          : (value) => setState(() => _selectedResidencyId = value),
      validator: (value) =>
          value == null ? strings.text('packages.form.toast.requiredMessage') : null,
    );
    final descriptionField = TextFormField(
      key: const ValueKey('packages-description'),
      controller: _description,
      maxLength: 255,
      enabled: !_submitting,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        labelText: strings.text('packages.description'),
        hintText: strings.text('packages.form.descriptionPlaceholder'),
      ),
      validator: (value) => value == null || value.trim().isEmpty
          ? strings.text('packages.form.toast.requiredMessage')
          : null,
    );

    return Form(
      key: _formKey,
      autovalidateMode: _validate
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns = constraints.maxWidth >= 768;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  key: const Key('packages-refresh-residencies'),
                  onPressed: _loadingResidencies ? null : _loadResidencies,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(
                    strings.text(
                      _loadingResidencies
                          ? 'packages.list.updating'
                          : 'packages.form.refreshResidencies',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_loadingResidencies) const LinearProgressIndicator(),
              if (_loadFailure != null)
                RequestFeedback(
                  failure: _loadFailure,
                  onRetry: _loadResidencies,
                ),
              const SizedBox(height: 12),
              if (twoColumns)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: residencyField),
                    const SizedBox(width: 16),
                    Expanded(child: descriptionField),
                  ],
                )
              else ...[
                residencyField,
                const SizedBox(height: 16),
                descriptionField,
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('packages-submit'),
                onPressed: canSubmit ? _submit : null,
                child: Text(
                  strings.text(
                    _submitting
                        ? 'packages.form.submitting'
                        : 'packages.form.submit',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
