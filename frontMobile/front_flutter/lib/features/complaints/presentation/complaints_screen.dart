import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../application/complaints_controller.dart';
import '../domain/complaint.dart';
import '../domain/complaint_access.dart';
import '../domain/complaints_repository.dart';
import 'complaint_strings.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({
    required this.access,
    required this.repository,
    this.buildingName,
    this.languageCode,
    this.onSessionExpired,
    this.onSignIn,
    this.shellManaged = false,
    super.key,
  });
  final ComplaintAccess access;
  final ComplaintsRepository repository;
  final String? buildingName;
  final String? languageCode;
  final VoidCallback? onSessionExpired;
  final VoidCallback? onSignIn;
  final bool shellManaged;

  @override
  State<ComplaintsScreen> createState() => ComplaintsScreenState();
}

class ComplaintsScreenState extends State<ComplaintsScreen> {
  late ComplaintsController _controller;
  Timer? _expiry;
  bool _showDetail = false;
  bool _showCreate = false;
  bool _dirty = false;
  bool _expiryNotified = false;
  Future<bool>? _leaveRequest;
  ComplaintStrings get _strings =>
      ComplaintStrings.of(context, previewLanguage: widget.languageCode);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() {
    _controller = ComplaintsController(
      repository: widget.repository,
      access: widget.access,
    )..addListener(_changed);
    _showCreate = widget.access.canCreate && !widget.access.canRead;
    _scheduleExpiry();
    unawaited(_controller.load());
  }

  void _changed() {
    if (_controller.sessionExpired && !_expiryNotified) {
      _expiryNotified = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSessionExpired?.call();
      });
    }
  }

  void _scheduleExpiry() {
    _expiry?.cancel();
    final date = widget.access.expiresAt;
    if (date != null) {
      final remaining = date.difference(DateTime.now());
      _expiry = Timer(
        remaining.isNegative ? Duration.zero : remaining,
        () => _controller.updateAccess(widget.access),
      );
    }
  }

  @override
  void didUpdateWidget(covariant ComplaintsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _controller.removeListener(_changed);
      _controller.dispose();
      _showDetail = _showCreate = _dirty = _expiryNotified = false;
      _initialize();
    } else if (oldWidget.access.sessionIdentity !=
        widget.access.sessionIdentity) {
      _showDetail = _showCreate = _dirty = _expiryNotified = false;
      _controller.updateAccess(widget.access);
      _scheduleExpiry();
      unawaited(_controller.load());
    }
  }

  @override
  void dispose() {
    _expiry?.cancel();
    _controller.removeListener(_changed);
    _controller.dispose();
    super.dispose();
  }

  Future<bool> confirmLeave() async {
    if (_leaveRequest != null) return _leaveRequest!;
    final request = _confirmLeave();
    _leaveRequest = request;
    try {
      return await request;
    } finally {
      _leaveRequest = null;
    }
  }

  Future<bool> _confirmLeave() async {
    if (_controller.isSubmitting) return false;
    if (!_dirty) return true;
    final strings = _strings;
    final discard = await _confirm(
      context,
      strings,
      _controller,
      title: 'discardTitle',
      body: 'discardBody',
      action: 'discardConfirm',
    );
    if (!mounted || !discard) return false;
    setState(() => _dirty = false);
    return true;
  }

  Future<void> _back() async {
    if (!await confirmLeave() || !mounted) return;
    setState(() {
      _showCreate = false;
      _showDetail = false;
    });
    _controller.clearSelection();
  }

  /// Returns Home only after local form/detail navigation has finished.
  Future<bool> handleShellBack() async {
    if (_controller.isSubmitting) return true;
    if (!_showCreate && !_showDetail && !_dirty) return false;
    await _back();
    return true;
  }

  Future<void> _select(Complaint complaint) async {
    if (!await confirmLeave() || !mounted) return;
    final expand = !_showDetail || _controller.selected?.id != complaint.id;
    setState(() {
      _showDetail = expand;
      _showCreate = false;
      _dirty = false;
    });
    if (expand) {
      await _controller.select(complaint.id);
    } else {
      _controller.clearSelection();
    }
  }

  Future<void> _filter({ComplaintStatus? status, String? category}) async {
    if (!await confirmLeave() || !mounted) return;
    setState(() {
      _showDetail = false;
      _showCreate = false;
      _dirty = false;
    });
    await _controller.setFilters(status: status, category: category);
  }

  Future<void> _scope(ComplaintScope scope) async {
    if (!await confirmLeave() || !mounted) return;
    setState(() {
      _showDetail = _showCreate = _dirty = false;
    });
    await _controller.setScope(scope);
  }

  void _notify(String message) {
    if (mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
      );
    }
  }

  void _draft(bool dirty) {
    if (mounted && _dirty != dirty) setState(() => _dirty = dirty);
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: HiveTheme.apply(Theme.of(context)),
    child: Builder(
      builder: (context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final strings = _strings;
          if (!_controller.access.canAccess || _controller.sessionExpired) {
            final prefix = _controller.sessionExpired
                ? 'expired'
                : _controller.access.isSignedIn
                ? 'denied'
                : 'signedOut';
            return _empty(
              strings.text('${prefix}Title'),
              strings.text('${prefix}Body'),
              action: prefix != 'denied' && widget.onSignIn != null
                  ? TextButton(
                      onPressed: widget.onSignIn,
                      child: Text(strings.text('signIn')),
                    )
                  : null,
            );
          }
          return PopScope(
            canPop:
                widget.shellManaged ||
                (!_showDetail &&
                    !_showCreate &&
                    !_dirty &&
                    !_controller.isSubmitting),
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && !widget.shellManaged) unawaited(_back());
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gutter = constraints.maxWidth < 768 ? 16.0 : 32.0;
                return ColoredBox(
                  color: widget.shellManaged
                      ? HiveColors.surface
                      : HiveColors.canvas,
                  child: SingleChildScrollView(
                    key: PageStorageKey(
                      'complaints-${widget.access.sessionIdentity}',
                    ),
                    padding: EdgeInsets.all(gutter),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(context, strings),
                        const SizedBox(height: 24),
                        if (_showCreate)
                          _CreateForm(
                            key: ValueKey(
                              'create-${widget.access.sessionIdentity}',
                            ),
                            controller: _controller,
                            strings: strings,
                            onDirty: _draft,
                            onCancel: _back,
                            onCreated: () {
                              if (!mounted) return;
                              setState(() {
                                _showCreate = !_controller.access.canRead;
                                _showDetail = _controller.access.canRead;
                                _dirty = false;
                              });
                              _notify(strings.text('successCreate'));
                            },
                          )
                        else if (!_controller.access.canRead)
                          _empty(
                            strings.text('deniedTitle'),
                            strings.text('deniedBody'),
                          )
                        else ...[
                          _filters(strings),
                          const SizedBox(height: 16),
                          if (_controller.loadFailed) ...[
                            _feedback(
                              strings.failure(_controller.loadFailure),
                              error: true,
                              action: TextButton(
                                onPressed:
                                    _controller.isLoading ||
                                        _controller.isSubmitting
                                    ? null
                                    : () => _controller.load(),
                                child: Text(strings.text('retry')),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_controller.isLoading &&
                              _controller.items.isNotEmpty)
                            const LinearProgressIndicator(),
                          _list(context, strings),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    ),
  );

  Widget _header(BuildContext context, ComplaintStrings strings) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            color: HiveColors.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                strings.text('title'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
        ],
      ),
      if (widget.buildingName?.isNotEmpty == true) ...[
        const SizedBox(height: 8),
        Text(
          widget.buildingName!,
          style: const TextStyle(color: HiveColors.secondary),
        ),
      ],
      if (!_showCreate) ...[
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (ComplaintScope.values
                    .where(_controller.access.canReadScope)
                    .length >
                1)
              for (final scope in ComplaintScope.values.where(
                _controller.access.canReadScope,
              ))
                FilledButton.tonal(
                  onPressed: _controller.isSubmitting
                      ? null
                      : () => _scope(scope),
                  style:
                      FilledButton.styleFrom(
                        backgroundColor: _controller.scope == scope
                            ? HiveColors.primary
                            : HiveColors.raised,
                        foregroundColor: _controller.scope == scope
                            ? HiveColors.canvas
                            : HiveColors.text,
                      ).copyWith(
                        side: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.focused)
                              ? BorderSide(
                                  color: _controller.scope == scope
                                      ? HiveColors.canvas
                                      : HiveColors.primary,
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                      ),
                  child: Semantics(
                    selected: _controller.scope == scope,
                    child: Text(strings.text(scope.name)),
                  ),
                ),
            if (_controller.access.canCreate)
              FilledButton.icon(
                key: const ValueKey('new-complaint'),
                onPressed: _controller.isSubmitting
                    ? null
                    : () async {
                        if (!await confirmLeave() || !mounted) return;
                        setState(() {
                          _showCreate = true;
                          _showDetail = false;
                          _dirty = false;
                        });
                        _controller.clearSelection();
                      },
                icon: const Icon(Icons.add, size: 16),
                label: Text(strings.text('newComplaint')),
              ),
            TextButton.icon(
              onPressed: _controller.isLoading || _controller.isSubmitting
                  ? null
                  : () => _controller.load(),
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(strings.text('refresh')),
            ),
          ],
        ),
      ],
    ],
  );

  Widget _filters(ComplaintStrings strings) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth < 500 ? constraints.maxWidth : 240.0;
      return Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          SizedBox(
            width: width,
            child: DropdownButtonFormField<ComplaintStatus>(
              key: ValueKey('status-${_controller.statusFilter}'),
              initialValue: _controller.statusFilter,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: strings.text('filterLabel'),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(strings.text('all'))),
                for (final value in ComplaintStatus.values.where(
                  (value) => value != ComplaintStatus.unknown,
                ))
                  DropdownMenuItem(
                    value: value,
                    child: Text(strings.text(value.name)),
                  ),
              ],
              onChanged: _controller.isSubmitting
                  ? null
                  : (value) => _filter(
                      status: value,
                      category: _controller.categoryFilter,
                    ),
            ),
          ),
          SizedBox(
            width: width,
            child: DropdownButtonFormField<String>(
              key: ValueKey('category-${_controller.categoryFilter}'),
              initialValue: _controller.categoryFilter,
              isExpanded: true,
              decoration: InputDecoration(labelText: strings.text('category')),
              items: [
                DropdownMenuItem(value: null, child: Text(strings.text('all'))),
                for (final value in complaintCategories)
                  DropdownMenuItem(
                    value: value,
                    child: Text(strings.text('category_$value')),
                  ),
              ],
              onChanged: _controller.isSubmitting
                  ? null
                  : (value) => _filter(
                      status: _controller.statusFilter,
                      category: value,
                    ),
            ),
          ),
        ],
      );
    },
  );

  Widget _list(BuildContext context, ComplaintStrings strings) {
    if (_controller.items.isEmpty && _controller.loadFailed) {
      return const SizedBox.shrink();
    }
    if (_controller.isLoading && _controller.items.isEmpty) {
      return _empty(strings.text('loading'), '', loading: true);
    }
    if (_controller.items.isEmpty) {
      return _empty(
        strings.text(
          _controller.statusFilter != null || _controller.categoryFilter != null
              ? 'filteredEmpty'
              : 'emptyTitle',
        ),
        _controller.loadFailed
            ? strings.text('loadError')
            : strings.text('emptyBody'),
      );
    }
    return Column(
      key: const ValueKey('complaint-list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in _controller.items) ...[
          Material(
            key: ValueKey('complaint-item-${item.id}'),
            color: HiveColors.canvas,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: HiveColors.raised),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  button: true,
                  expanded: _showDetail && _controller.selected?.id == item.id,
                  child: InkWell(
                    key: ValueKey('complaint-toggle-${item.id}'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: _controller.isSubmitting
                        ? null
                        : () => _select(item),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                _showDetail &&
                                        _controller.selected?.id == item.id
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 20,
                                color: HiveColors.secondary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _StatusBadge(
                                status: item.status,
                                strings: strings,
                              ),
                              Text(strings.text('category_${item.category}')),
                              Text(
                                strings.date(item.createdAt, context: context),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_showDetail && _controller.selected?.id == item.id) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: HiveColors.raised,
                    ),
                  ),
                  KeyedSubtree(
                    key: ValueKey('complaint-expanded-${item.id}'),
                    child: _detail(context, strings),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_controller.hasMore)
          TextButton(
            onPressed: _controller.isLoadingMore || _controller.isSubmitting
                ? null
                : () => _controller.load(more: true),
            child: Text(
              strings.text(_controller.isLoadingMore ? 'loading' : 'loadMore'),
            ),
          ),
      ],
    );
  }

  Widget _detail(BuildContext context, ComplaintStrings strings) {
    final selected = _controller.selected;
    if (_controller.isDetailLoading && selected?.hasDetails != true) {
      return _empty(strings.text('loading'), '', loading: true);
    }
    if (_controller.detailFailure != null && selected?.hasDetails != true) {
      return _feedback(
        strings.failure(_controller.detailFailure),
        error: true,
        backgroundColor: Colors.transparent,
        action: selected == null
            ? null
            : TextButton(
                onPressed: () => _controller.select(selected.id),
                child: Text(strings.text('retry')),
              ),
      );
    }
    if (selected == null || !selected.hasDetails) {
      return _empty(strings.text('selectTitle'), strings.text('selectBody'));
    }
    return _ComplaintDetail(
      key: ValueKey('${widget.access.sessionIdentity}:${selected.id}'),
      complaint: selected,
      controller: _controller,
      strings: strings,
      onSuccess: _notify,
      onDirty: _draft,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.strings});
  final ComplaintStatus status;
  final ComplaintStrings strings;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ComplaintStatus.open => HiveColors.primary,
      ComplaintStatus.inAnalysis => HiveColors.warning,
      _ => HiveColors.secondary,
    };
    return Container(
      decoration: BoxDecoration(
        color: HiveColors.raised,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == ComplaintStatus.closed
                ? Icons.check_circle_outline
                : Icons.info_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              strings.text(switch (status) {
                ComplaintStatus.open => 'statusOpen',
                ComplaintStatus.inAnalysis => 'statusInAnalysis',
                ComplaintStatus.closed => 'statusClosed',
                ComplaintStatus.unknown => 'statusUnknown',
              }),
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplaintDetail extends StatefulWidget {
  const _ComplaintDetail({
    required this.complaint,
    required this.controller,
    required this.strings,
    required this.onSuccess,
    required this.onDirty,
    super.key,
  });
  final Complaint complaint;
  final ComplaintsController controller;
  final ComplaintStrings strings;
  final ValueChanged<String> onSuccess;
  final ValueChanged<bool> onDirty;
  @override
  State<_ComplaintDetail> createState() => _ComplaintDetailState();
}

class _ComplaintDetailState extends State<_ComplaintDetail> {
  final _reply = TextEditingController();
  final _replyFocus = FocusNode();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _reply.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  Future<void> _respond() async {
    if (!_form.currentState!.validate()) {
      _replyFocus.requestFocus();
      return;
    }
    final success = await widget.controller.respond(_reply.text);
    if (!mounted) return;
    if (success) {
      _reply.clear();
      widget.onDirty(false);
      widget.onSuccess(widget.strings.text('successReply'));
    }
  }

  Future<void> _close() async {
    final id = widget.complaint.id;
    final identity = widget.controller.access.sessionIdentity;
    if (!await _confirm(
      context,
      widget.strings,
      widget.controller,
      title: 'closeTitle',
      body: _reply.text.isEmpty ? 'closeBody' : 'closeBodyWithDraft',
      action: 'confirmClose',
      complaintId: id,
    )) {
      return;
    }
    if (!mounted ||
        widget.controller.selected?.id != id ||
        widget.controller.access.sessionIdentity != identity) {
      return;
    }
    final success = await widget.controller.close();
    if (mounted && success) {
      _reply.clear();
      widget.onDirty(false);
      widget.onSuccess(widget.strings.text('successClose'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.complaint;
    final controller = widget.controller;
    final strings = widget.strings;
    final busy = controller.isSubmitting || controller.isDetailLoading;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.isDetailLoading) const LinearProgressIndicator(),
          _StatusBadge(status: item.status, strings: strings),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              item.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${strings.text('category')}: ${strings.text('category_${item.category}')}',
          ),
          const SizedBox(height: 8),
          SelectableText(
            '${strings.text('protocol')}: ${item.id}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${strings.text('createdAt')} ${strings.date(item.createdAt, context: context)}',
          ),
          const SizedBox(height: 8),
          Text(
            '${strings.text('updatedAt')} ${strings.date(item.updatedAt, context: context)}',
          ),
          _detailDivider,
          Text(
            strings.text('report'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          SelectableText(item.description),
          _detailDivider,
          Text(
            strings.text('responseTitle'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (item.responses.isEmpty) Text(strings.text('noResponses')),
          for (final response in item.responses) ...[
            Text(
              strings.text(
                response.isAdministrative
                    ? 'responseFromBuilding'
                    : 'responseFromResidency',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SelectableText(response.message),
            const SizedBox(height: 4),
            Text(
              strings.date(response.createdAt, context: context),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
          ],
          _detailDivider,
          Text(
            strings.text('history'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final change in item.history)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _StatusBadge(status: change.status, strings: strings),
                  Text(strings.date(change.createdAt, context: context)),
                ],
              ),
            ),
          if (item.status == ComplaintStatus.closed) ...[
            const SizedBox(height: 24),
            _feedback(
              strings.text('closedMessage'),
              backgroundColor: Colors.transparent,
            ),
          ],
          if (controller.mutationFailed) ...[
            const SizedBox(height: 16),
            _feedback(
              strings.failure(controller.mutationFailure),
              error: true,
              backgroundColor: Colors.transparent,
            ),
          ],
          if (controller.canAct) ...[
            _detailDivider,
            if (controller.canRespond)
              Form(
                key: _form,
                child: TextFormField(
                  key: const ValueKey('complaint-response'),
                  controller: _reply,
                  focusNode: _replyFocus,
                  enabled: !busy,
                  minLines: 4,
                  maxLines: 10,
                  maxLength: 5000,
                  onChanged: (value) => widget.onDirty(value.isNotEmpty),
                  decoration: InputDecoration(
                    labelText: strings.text('replyLabel'),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? strings.text('requiredResponse')
                      : value.trim().length > 5000 || value.contains('\u0000')
                      ? strings.text('limitResponse')
                      : null,
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (controller.canRespond)
                  FilledButton.icon(
                    key: const ValueKey('send-response'),
                    onPressed: busy ? null : _respond,
                    icon: const Icon(Icons.send_outlined, size: 16),
                    label: Text(
                      strings.text(busy ? 'sending' : 'sendResponse'),
                    ),
                  ),
                if (controller.canChangeStatus &&
                    item.status == ComplaintStatus.open)
                  TextButton(
                    onPressed: busy
                        ? null
                        : () async {
                            final success = await controller.changeStatus(
                              ComplaintStatus.inAnalysis,
                            );
                            if (mounted && success) {
                              widget.onSuccess(strings.text('successStatus'));
                            }
                          },
                    child: Text(strings.text('markInAnalysis')),
                  ),
                if (controller.canChangeStatus)
                  TextButton.icon(
                    key: const ValueKey('close-complaint'),
                    onPressed:
                        busy ||
                            !item.responses.any(
                              (response) => response.isAdministrative,
                            )
                        ? null
                        : _close,
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(strings.text('closeComplaint')),
                  ),
              ],
            ),
            if (controller.canChangeStatus &&
                !item.responses.any(
                  (response) => response.isAdministrative,
                )) ...[
              const SizedBox(height: 8),
              Text(strings.text('responseRequired')),
            ],
          ],
        ],
      ),
    );
  }
}

class _CreateForm extends StatefulWidget {
  const _CreateForm({
    required this.controller,
    required this.strings,
    required this.onDirty,
    required this.onCancel,
    required this.onCreated,
    super.key,
  });
  final ComplaintsController controller;
  final ComplaintStrings strings;
  final ValueChanged<bool> onDirty;
  final VoidCallback onCancel;
  final VoidCallback onCreated;
  @override
  State<_CreateForm> createState() => _CreateFormState();
}

class _CreateFormState extends State<_CreateForm> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _titleFocus = FocusNode();
  final _categoryFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  String? _category;
  bool _busy = false;
  void _dirty() => widget.onDirty(
    _title.text.isNotEmpty || _description.text.isNotEmpty || _category != null,
  );
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _titleFocus.dispose();
    _categoryFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_form.currentState!.validate()) {
      if (_title.text.trim().isEmpty || _title.text.trim().length > 200) {
        _titleFocus.requestFocus();
      } else if (_category == null) {
        _categoryFocus.requestFocus();
      } else {
        _descriptionFocus.requestFocus();
      }
      return;
    }
    setState(() => _busy = true);
    final success = await widget.controller.create(
      _title.text,
      _description.text,
      category: _category!,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (success) {
      _form.currentState?.reset();
      _title.clear();
      _description.clear();
      setState(() => _category = null);
      widget.onDirty(false);
      widget.onCreated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return _panel(
      Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                strings.text('createTitle'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const ValueKey('complaint-subject'),
              controller: _title,
              focusNode: _titleFocus,
              enabled: !_busy,
              autofocus: true,
              maxLength: 200,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _dirty(),
              decoration: InputDecoration(
                labelText: strings.text('subjectLabel'),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? strings.text('requiredSubject')
                  : value.trim().length > 200 || value.contains('\u0000')
                  ? strings.text('limitTitle')
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const ValueKey('complaint-category'),
              focusNode: _categoryFocus,
              isExpanded: true,
              decoration: InputDecoration(labelText: strings.text('category')),
              items: [
                for (final category in complaintCategories)
                  DropdownMenuItem(
                    value: category,
                    child: Text(strings.text('category_$category')),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (value) {
                      setState(() => _category = value);
                      _dirty();
                    },
              validator: (value) =>
                  value == null ? strings.text('failureValidation') : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('complaint-description'),
              controller: _description,
              focusNode: _descriptionFocus,
              enabled: !_busy,
              minLines: 5,
              maxLines: 12,
              maxLength: 10000,
              onChanged: (_) => _dirty(),
              decoration: InputDecoration(
                labelText: strings.text('descriptionLabel'),
                alignLabelWithHint: true,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? strings.text('requiredDescription')
                  : value.trim().length > 10000 || value.contains('\u0000')
                  ? strings.text('limitDescription')
                  : null,
            ),
            const SizedBox(height: 16),
            _feedback(strings.text('privateNotice')),
            if (widget.controller.mutationFailed) ...[
              const SizedBox(height: 12),
              _feedback(
                strings.failure(widget.controller.mutationFailure),
                error: true,
              ),
            ],
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: _busy ? null : widget.onCancel,
                  child: Text(strings.text('cancel')),
                ),
                FilledButton(
                  key: const ValueKey('submit-complaint'),
                  onPressed: _busy ? null : _submit,
                  child: Text(strings.text(_busy ? 'saving' : 'submit')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const _detailDivider = Divider(
  height: 33,
  thickness: 1,
  color: HiveColors.raised,
);

Widget _panel(Widget child, {Color backgroundColor = HiveColors.surface}) =>
    DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
Widget _empty(
  String title,
  String body, {
  Widget? action,
  bool loading = false,
}) => Padding(
  padding: const EdgeInsets.all(24),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (loading) CircularProgressIndicator(semanticsLabel: title),
      const SizedBox(height: 16),
      Text(title, textAlign: TextAlign.center),
      if (body.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center),
      ],
      ?action,
    ],
  ),
);
Widget _feedback(
  String message, {
  bool error = false,
  Widget? action,
  Color backgroundColor = HiveColors.surface,
}) => Semantics(
  liveRegion: true,
  child: _panel(
    backgroundColor: backgroundColor,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              error ? Icons.error_outline : Icons.info_outline,
              color: error ? HiveColors.danger : HiveColors.secondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: error ? HiveColors.danger : HiveColors.body,
                ),
              ),
            ),
          ],
        ),
        ?action,
      ],
    ),
  ),
);

Future<bool> _confirm(
  BuildContext context,
  ComplaintStrings strings,
  ComplaintsController controller, {
  required String title,
  required String body,
  required String action,
  String? complaintId,
}) async {
  final identity = controller.access.sessionIdentity;
  bool closing = false;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: const Color(0x99000000),
        builder: (dialogContext) => AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final valid =
                !controller.sessionExpired &&
                controller.access.canAccess &&
                controller.access.sessionIdentity == identity &&
                (complaintId == null || controller.selected?.id == complaintId);
            if (!valid && !closing) {
              closing = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (dialogContext.mounted &&
                    ModalRoute.of(dialogContext)?.isCurrent == true) {
                  Navigator.pop(dialogContext, false);
                }
              });
            }
            return AlertDialog(
              title: Text(strings.text(title)),
              content: Text(strings.text(body)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(strings.text('cancel')),
                ),
                FilledButton(
                  onPressed: valid
                      ? () => Navigator.pop(dialogContext, true)
                      : null,
                  child: Text(strings.text(action)),
                ),
              ],
            );
          },
        ),
      ) ??
      false;
}
