import 'package:flutter/material.dart';

import '../shared/request_feedback.dart';
import '../../helpers/visitor_service.dart';
import '../../lang/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../types/api_failure.dart';
import '../../types/user_session.dart';
import '../../types/visitor_access.dart';

class VisitorAccessResidencyList extends StatefulWidget {
  const VisitorAccessResidencyList({
    super.key,
    required this.session,
    required this.service,
    required this.onSessionExpired,
  });

  final UserSession session;
  final VisitorService service;
  final VoidCallback onSessionExpired;

  @override
  State<VisitorAccessResidencyList> createState() =>
      _VisitorAccessResidencyListState();
}

class _VisitorAccessResidencyListState
    extends State<VisitorAccessResidencyList> {
  List<VisitorAccess>? _items;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final items = await widget.service.list(widget.session);
      if (!mounted) return;
      setState(() => _items = items);
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.failure == ApiFailure.unauthorized) {
        widget.onSessionExpired();
        return;
      }
      setState(() => _failed = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final items = _items;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: HiveColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const Key('refresh-visitor-access'),
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(
                  _loading
                      ? strings.text('visitorAccess.list.updating')
                      : strings.text('refresh'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (items == null && _loading)
              Text(
                strings.text('visitorAccess.list.loading'),
                style: _secondary(context),
              )
            else if (_failed && items == null)
              RequestFeedback(
                message: strings.text('visitorAccess.list.error'),
                onRetry: _load,
              )
            else if (items != null && items.isEmpty && !_failed)
              Text(
                strings.text('visitorAccess.list.empty'),
                style: _secondary(context),
              )
            else if (items != null) ...[
              if (_failed)
                RequestFeedback(
                  message: strings.text('visitorAccess.list.error'),
                  onRetry: _load,
                ),
              _table(context, strings, items),
            ],
          ],
        ),
      ),
    );
  }

  Widget _table(
    BuildContext context,
    AppLocalizations strings,
    List<VisitorAccess> items,
  ) {
    final headers = [
      strings.text('visitorAccess.table.visitor'),
      strings.text('visitorAccess.table.residency'),
      strings.text('visitorAccess.table.cpf'),
      strings.text('visitorAccess.table.rg'),
      strings.text('visitorAccess.table.entry'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: const TableBorder(
          horizontalInside: BorderSide(color: HiveColors.raised),
        ),
        children: [
          TableRow(
            children: [for (final header in headers) _headerCell(header)],
          ),
          for (final access in items)
            TableRow(
              children: [
                _cell(access.name),
                _cell(access.residencyLabel),
                _cell(access.cpf),
                _cell(access.rg),
                _cell(_formatEntry(context, access.entryAt)),
              ],
            ),
        ],
      ),
    );
  }
}

TextStyle _secondary(BuildContext context) =>
    Theme.of(context).textTheme.labelMedium!
        .copyWith(color: HiveColors.secondary, fontWeight: FontWeight.w400);

Widget _headerCell(String label) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        color: HiveColors.secondary,
      ),
    ),
  );
}

Widget _cell(String value) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
    child: Text(
      value,
      style: const TextStyle(
        fontSize: 14,
        height: 20 / 14,
        color: HiveColors.text,
      ),
    ),
  );
}

String _formatEntry(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final locale = MaterialLocalizations.of(context);
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${locale.formatShortDate(local)} $hour:$minute';
}
