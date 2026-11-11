import 'package:flutter/material.dart';

import '../../lang/app_localizations.dart';
import '../../types/api_failure.dart';
import '../shared/request_feedback.dart';

/// A lazy level of the group -> residency -> resident tree.
class ResidentsBranch<T> extends StatefulWidget {
  const ResidentsBranch({super.key, required this.label, required this.load, required this.itemBuilder, required this.emptyMessage, required this.onSessionExpired, required this.nodeKey});
  final String label;
  final String nodeKey;
  final Future<List<T>> Function() load;
  final Widget Function(T) itemBuilder;
  final String emptyMessage;
  final VoidCallback onSessionExpired;

  @override
  State<ResidentsBranch<T>> createState() => _ResidentsBranchState<T>();
}

class _ResidentsBranchState<T> extends State<ResidentsBranch<T>> {
  bool _open = false;
  bool _loading = false;
  List<T>? _items;
  ApiFailure? _error;

  Future<void> _load() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      final items = await widget.load();
      if (mounted) setState(() => _items = items);
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

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        expanded: _open,
        child: TextButton(
          key: ValueKey(widget.nodeKey),
          style: TextButton.styleFrom(alignment: Alignment.centerLeft),
          onPressed: () {
            setState(() => _open = !_open);
            if (_open && _items == null) _load();
          },
          child: Row(children: [
            Icon(_open ? Icons.expand_more : Icons.chevron_right, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.label)),
          ]),
        ),
      ),
      if (_open)
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_loading) Semantics(label: AppLocalizations.of(context).text('residents.loading'), child: const LinearProgressIndicator()),
            if (_error != null) RequestFeedback(failure: _error, onRetry: _load),
            if (_items != null && _items!.isEmpty) RequestFeedback(message: widget.emptyMessage),
            if (_items != null) ..._items!.map(widget.itemBuilder),
          ]),
        ),
    ],
  );
}
