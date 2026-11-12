import 'package:flutter/material.dart';

import '../../helpers/packages_service.dart';
import '../../lang/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../types/api_failure.dart';
import '../../types/delivery_package.dart';
import '../../types/user_session.dart';
import '../shared/request_feedback.dart';
import 'package_status_badge.dart';

/// Lists packages of the building or of the user's residency. Only the
/// residency scope can confirm a delivery, as in the React screen.
class PackageList extends StatefulWidget {
  const PackageList({
    super.key,
    required this.session,
    required this.service,
    required this.scope,
    required this.onSessionExpired,
  });

  final UserSession session;
  final PackagesService service;
  final PackageScope scope;
  final VoidCallback onSessionExpired;

  @override
  State<PackageList> createState() => _PackageListState();
}

class _PackageListState extends State<PackageList> {
  List<DeliveryPackage>? _packages;
  bool _loading = false;
  ApiFailure? _failure;
  String? _confirmingId;

  bool get _isResidency => widget.scope == PackageScope.residency;

  @override
  void initState() {
    super.initState();
    _load();
  }

  ApiFailure _failureOf(Object error) =>
      error is ApiException ? error.failure : ApiFailure.unexpected;

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final packages = await widget.service.listPackages(
        widget.session,
        widget.scope,
      );
      if (mounted) setState(() => _packages = packages);
    } catch (error) {
      if (!mounted) return;
      final failure = _failureOf(error);
      if (failure == ApiFailure.unauthorized) {
        widget.onSessionExpired();
      } else {
        // A read failure keeps any previous content and is never shown as empty.
        setState(() => _failure = failure);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  Future<void> _confirm(DeliveryPackage item) async {
    if (_confirmingId != null) return;
    final strings = AppLocalizations.of(context);
    setState(() => _confirmingId = item.id);
    try {
      await widget.service.confirmDelivery(widget.session, item.id);
      if (!mounted) return;
      _notify(strings.text('packages.list.toast.confirmMessage'));
      setState(() => _confirmingId = null);
      await _load();
    } catch (error) {
      if (!mounted) return;
      if (_failureOf(error) == ApiFailure.unauthorized) {
        widget.onSessionExpired();
      } else {
        _notify(strings.text('packages.list.toast.confirmError'));
      }
    } finally {
      if (mounted) setState(() => _confirmingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final packages = _packages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            key: const Key('packages-refresh'),
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(
              strings.text(
                _loading ? 'packages.list.updating' : 'packages.list.refresh',
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_loading)
          Semantics(
            label: strings.text('packages.loading'),
            child: const LinearProgressIndicator(),
          ),
        if (_failure != null) RequestFeedback(failure: _failure, onRetry: _load),
        if (packages != null && packages.isEmpty && _failure == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              strings.text('packages.list.empty'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        if (packages != null)
          for (final item in packages)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PackageCard(
                key: ValueKey('package-${item.id}'),
                item: item,
                showResidency: !_isResidency,
                showConfirm: _isResidency,
                confirming: _confirmingId == item.id,
                busy: _confirmingId != null,
                onConfirm: () => _confirm(item),
              ),
            ),
      ],
    );
  }

}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    super.key,
    required this.item,
    required this.showResidency,
    required this.showConfirm,
    required this.confirming,
    required this.busy,
    required this.onConfirm,
  });

  final DeliveryPackage item;
  final bool showResidency;
  final bool showConfirm;
  final bool confirming;
  final bool busy;
  final VoidCallback onConfirm;

  String _format(BuildContext context, DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final material = MaterialLocalizations.of(context);
    return '${material.formatShortDate(local)} '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context).textTheme;
    Widget meta(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.bodySmall),
        Text(value, style: theme.bodyMedium),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HiveColors.canvas,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HiveColors.raised),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 120),
                  child: Text(item.description, style: theme.titleMedium),
                ),
                PackageStatusBadge(status: item.status),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                if (showResidency)
                  meta(strings.text('packages.table.residency'), item.residencyName),
                meta(
                  strings.text('packages.table.receivedAt'),
                  _format(context, item.createdAt),
                ),
                meta(
                  strings.text('packages.table.deliveredAt'),
                  _format(context, item.deliveredAt),
                ),
              ],
            ),
            if (showConfirm) ...[
              const Divider(height: 33, thickness: 1, color: HiveColors.raised),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  key: ValueKey('package-confirm-${item.id}'),
                  onPressed: item.status == DeliveryStatus.pending && !busy
                      ? onConfirm
                      : null,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(
                    strings.text(
                      confirming
                          ? 'packages.list.confirming'
                          : 'packages.list.confirm',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
