import 'dart:async';

import 'package:flutter/material.dart';

import '../application/complaints_controller.dart';
import '../domain/complaint.dart';
import '../domain/complaint_access.dart';
import '../domain/complaints_repository.dart';
import 'complaint_strings.dart';
import 'complaint_theme.dart';

/// Feature content for the existing application shell. It owns no login,
/// storage, global navigation or HTTP client.
class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({
    required this.access,
    required this.repository,
    this.buildingName,
    this.languageCode,
    this.onSessionExpired,
    this.onSignIn,
    super.key,
  });

  final ComplaintAccess access;
  final ComplaintsRepository repository;
  final String? buildingName;
  final String? languageCode;
  final VoidCallback? onSessionExpired;
  final VoidCallback? onSignIn;

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  late ComplaintsController _controller;
  Timer? _expiryTimer;
  ComplaintStatus? _filter;
  bool _showDetail = false;
  bool _expiryNotified = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() {
    _controller = ComplaintsController(
      repository: widget.repository,
      access: widget.access,
    )..addListener(_onStateChanged);
    _scheduleExpiry();
    unawaited(_controller.load());
  }

  void _onStateChanged() {
    if (_controller.sessionExpired && !_expiryNotified) {
      _expiryNotified = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.sessionExpired) {
          widget.onSessionExpired?.call();
        }
      });
    }
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final expiry = widget.access.expiresAt;
    if (expiry == null) return;
    final remaining = expiry.difference(DateTime.now());
    _expiryTimer = Timer(remaining.isNegative ? Duration.zero : remaining, () {
      _controller.updateAccess(widget.access);
    });
  }

  @override
  void didUpdateWidget(covariant ComplaintsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _controller.updateAccess(const ComplaintAccess.signedOut());
      _controller.removeListener(_onStateChanged);
      _controller.dispose();
      _filter = null;
      _showDetail = false;
      _expiryNotified = false;
      _initialize();
    } else if (oldWidget.access != widget.access) {
      _expiryNotified = false;
      _controller.updateAccess(widget.access);
      _filter = null;
      _showDetail = false;
      _scheduleExpiry();
      unawaited(_controller.load());
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _create(
    BuildContext localContext,
    ComplaintStrings strings,
  ) async {
    final sessionIdentity = widget.access.sessionIdentity;
    final created = await showDialog<bool>(
      context: localContext,
      barrierDismissible: false,
      builder: (_) =>
          _CreateComplaintDialog(controller: _controller, strings: strings),
    );
    if (!mounted ||
        created != true ||
        widget.access.sessionIdentity != sessionIdentity) {
      return;
    }
    setState(() {
      _filter = null;
      _showDetail = true;
    });
    _notify(strings.text('successCreate'));
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  void _select(Complaint complaint) {
    _controller.select(complaint.id);
    setState(() => _showDetail = true);
  }

  void _changeFilter(ComplaintStatus? value) {
    setState(() {
      _filter = value;
      _showDetail = false;
    });
    final matches = _controller.items.where(
      (item) => value == null || item.status == value,
    );
    if (matches.isNotEmpty) _controller.select(matches.first.id);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ComplaintStrings.forLanguage(
      widget.languageCode ?? Localizations.localeOf(context).languageCode,
    );
    return Theme(
      data: ComplaintTheme.apply(Theme.of(context)),
      child: Builder(
        builder: (context) {
          final colors = ComplaintPalette.of(context);
          return ColoredBox(
            color: colors.canvas,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (!_controller.access.canRead || _controller.sessionExpired) {
                  final expired =
                      _controller.sessionExpired ||
                      _controller.access.isExpired;
                  final prefix = expired
                      ? 'expired'
                      : _controller.access.isSignedIn
                      ? 'denied'
                      : 'signedOut';
                  return _EmptyContent(
                    icon: Icons.lock_outline,
                    title: strings.text('${prefix}Title'),
                    message: strings.text('${prefix}Body'),
                    action: prefix != 'denied' && widget.onSignIn != null
                        ? FilledButton(
                            onPressed: widget.onSignIn,
                            child: Text(strings.text('signIn')),
                          )
                        : null,
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final wide =
                        constraints.maxWidth >= 1024 &&
                        constraints.maxHeight >= 600;
                    final gutter = constraints.maxWidth < 600
                        ? 16.0
                        : wide
                        ? 32.0
                        : 24.0;
                    final visible = _controller.items
                        .where(
                          (item) => _filter == null || item.status == _filter,
                        )
                        .toList();
                    final selected = _controller.selected;
                    final detail =
                        selected != null &&
                            (_filter == null || selected.status == _filter)
                        ? selected
                        : null;
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Padding(
                          padding: EdgeInsets.all(gutter),
                          child: _page(
                            context,
                            strings,
                            colors,
                            visible,
                            detail,
                            wide,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _page(
    BuildContext context,
    ComplaintStrings strings,
    ComplaintPalette colors,
    List<Complaint> visible,
    Complaint? detail,
    bool wide,
  ) {
    final body = _body(context, strings, visible, detail, wide);
    final content = Column(
      mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context, strings, colors),
        const SizedBox(height: 20),
        if (wide || !_showDetail) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterChip(null, strings.text('all')),
              for (final status in ComplaintStatus.values)
                _filterChip(status, strings.text(status.name)),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (_controller.loadFailed) ...[
          _InlineFeedback(
            message: strings.text('loadError'),
            isError: true,
            action: TextButton(
              onPressed: _controller.isLoading ? null : _controller.load,
              child: Text(strings.text('retry')),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_controller.isLoading && _controller.items.isNotEmpty)
          LinearProgressIndicator(
            semanticsLabel: strings.text('loading'),
            minHeight: 2,
          ),
        if (wide) Expanded(child: body) else body,
      ],
    );
    // The header must scroll too when the available height is consumed by
    // large text or the keyboard; it must never squeeze content below zero.
    return wide ? content : SingleChildScrollView(child: content);
  }

  Widget _header(
    BuildContext context,
    ComplaintStrings strings,
    ComplaintPalette colors,
  ) {
    final manager = _controller.access.canManage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.buildingName?.trim().isNotEmpty ?? false) ...[
          Text(
            widget.buildingName!,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.accent),
          ),
          const SizedBox(height: 8),
        ],
        Semantics(
          header: true,
          child: Text(
            strings.text(manager ? 'titleManager' : 'titleResident'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.text(manager ? 'subtitleManager' : 'subtitleResident'),
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (_controller.access.canCreate)
              FilledButton.icon(
                key: const ValueKey('new-complaint'),
                onPressed: () => _create(context, strings),
                icon: const Icon(Icons.add, size: 20),
                label: Text(strings.text('newComplaint')),
              ),
            TextButton.icon(
              onPressed: _controller.isLoading || _controller.isSubmitting
                  ? null
                  : _controller.load,
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(strings.text('refresh')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _filterChip(ComplaintStatus? value, String label) => FilterChip(
    label: Text(label),
    selected: _filter == value,
    showCheckmark: false,
    onSelected: (_) => _changeFilter(value),
  );

  Widget _body(
    BuildContext context,
    ComplaintStrings strings,
    List<Complaint> items,
    Complaint? selected,
    bool wide,
  ) {
    if (_controller.isLoading && _controller.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(semanticsLabel: strings.text('loading')),
            const SizedBox(height: 16),
            Text(strings.text('loading')),
          ],
        ),
      );
    }
    if (_controller.items.isEmpty && !_controller.loadFailed) {
      return _EmptyContent(
        icon: Icons.chat_bubble_outline,
        title: strings.text('emptyTitle'),
        message: strings.text('emptyBody'),
      );
    }
    if (_controller.items.isEmpty) return const SizedBox.shrink();
    final list = items.isEmpty
        ? _EmptyContent(
            icon: Icons.filter_alt_off_outlined,
            title: strings.text('filteredEmpty'),
          )
        : ListView.separated(
            key: const ValueKey('complaint-list'),
            shrinkWrap: !wide,
            physics: wide ? null : const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _ComplaintTile(
              complaint: items[index],
              selected: wide && selected?.id == items[index].id,
              strings: strings,
              onTap: () => _select(items[index]),
            ),
          );
    final detail = selected == null
        ? _EmptyContent(
            icon: Icons.forum_outlined,
            title: strings.text('selectTitle'),
            message: strings.text('selectBody'),
          )
        : _ComplaintDetail(
            key: ValueKey(selected.id),
            complaint: selected,
            controller: _controller,
            strings: strings,
            onSuccess: _notify,
          );
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 300, child: list),
          const SizedBox(width: 24),
          Expanded(child: detail),
        ],
      );
    }
    if (!_showDetail || selected == null) return list;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _showDetail = false),
            icon: const Icon(Icons.arrow_back, size: 20),
            label: Text(strings.text('backToList')),
          ),
        ),
        const SizedBox(height: 8),
        detail,
      ],
    );
  }
}

class _ComplaintTile extends StatelessWidget {
  const _ComplaintTile({
    required this.complaint,
    required this.selected,
    required this.strings,
    required this.onTap,
  });

  final Complaint complaint;
  final bool selected;
  final ComplaintStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ComplaintPalette.of(context);
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? colors.selection : colors.base,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint.subject,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                _StatusBadge(status: complaint.status, strings: strings),
                const SizedBox(height: 12),
                Text(
                  '${complaint.protocol} · ${strings.date(complaint.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.strings});
  final ComplaintStatus status;
  final ComplaintStrings strings;

  @override
  Widget build(BuildContext context) {
    final colors = ComplaintPalette.of(context);
    final (foreground, background, icon) = switch (status) {
      ComplaintStatus.open => (
        colors.warning,
        colors.warningBackground,
        Icons.schedule,
      ),
      ComplaintStatus.answered => (
        colors.info,
        colors.infoBackground,
        Icons.chat_bubble_outline,
      ),
      ComplaintStatus.closed => (
        colors.success,
        colors.successBackground,
        Icons.check_circle_outline,
      ),
    };
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              strings.text(switch (status) {
                ComplaintStatus.open => 'statusOpen',
                ComplaintStatus.answered => 'statusAnswered',
                ComplaintStatus.closed => 'statusClosed',
              }),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: foreground),
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
    super.key,
  });
  final Complaint complaint;
  final ComplaintsController controller;
  final ComplaintStrings strings;
  final ValueChanged<String> onSuccess;

  @override
  State<_ComplaintDetail> createState() => _ComplaintDetailState();
}

class _ComplaintDetailState extends State<_ComplaintDetail> {
  final _reply = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _failed = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _respond() async {
    if (!_form.currentState!.validate()) return;
    final success = await widget.controller.respond(_reply.text.trim());
    if (!mounted) return;
    setState(() => _failed = !success);
    if (success) {
      _reply.clear();
      widget.onSuccess(widget.strings.text('successReply'));
    }
  }

  Future<void> _close() async {
    final strings = widget.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.text('closeTitle')),
        content: Text(strings.text('closeBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.text('confirmClose')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final success = await widget.controller.close();
    if (!mounted) return;
    setState(() => _failed = !success);
    if (success) widget.onSuccess(strings.text('successClose'));
  }

  @override
  Widget build(BuildContext context) {
    final colors = ComplaintPalette.of(context);
    final strings = widget.strings;
    final complaint = widget.complaint;
    final manager = widget.controller.access.canManage;
    final closed = complaint.status == ComplaintStatus.closed;
    final busy = widget.controller.isSubmitting;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.base,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusBadge(status: complaint.status, strings: strings),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                complaint.subject,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${strings.text('protocol')} ${complaint.protocol}',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 4),
            Text(
              '${strings.text('createdAt')} ${strings.date(complaint.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 32),
            Text(
              strings.text('report'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            SelectableText(complaint.description),
            const SizedBox(height: 32),
            Text(
              strings.text('responseTitle'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            if (complaint.responses.isEmpty)
              Text(
                strings.text('noResponses'),
                style: TextStyle(color: colors.muted),
              ),
            for (final response in complaint.responses) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.raised,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(response.message),
                    const SizedBox(height: 12),
                    Text(
                      strings.date(response.createdAt),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (closed) ...[
              const SizedBox(height: 24),
              _InlineFeedback(message: strings.text('closedMessage')),
            ],
            if (_failed) ...[
              const SizedBox(height: 16),
              _InlineFeedback(
                message: strings.text('mutationError'),
                isError: true,
              ),
            ],
            if (manager && !closed) ...[
              const SizedBox(height: 32),
              Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const ValueKey('complaint-response'),
                      controller: _reply,
                      enabled: !busy,
                      minLines: 4,
                      maxLines: 10,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        labelText: strings.text('replyLabel'),
                        alignLabelWithHint: true,
                        hintText: strings.text('replyHint'),
                      ),
                      validator: (value) => value?.trim().isNotEmpty == true
                          ? null
                          : strings.text('requiredResponse'),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          key: const ValueKey('send-response'),
                          onPressed: busy ? null : _respond,
                          icon: const Icon(Icons.send_outlined, size: 20),
                          label: Text(
                            strings.text(busy ? 'sending' : 'sendResponse'),
                          ),
                        ),
                        TextButton.icon(
                          key: const ValueKey('close-complaint'),
                          onPressed: busy ? null : _close,
                          icon: const Icon(Icons.check, size: 20),
                          label: Text(strings.text('closeComplaint')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreateComplaintDialog extends StatefulWidget {
  const _CreateComplaintDialog({
    required this.controller,
    required this.strings,
  });
  final ComplaintsController controller;
  final ComplaintStrings strings;

  @override
  State<_CreateComplaintDialog> createState() => _CreateComplaintDialogState();
}

class _CreateComplaintDialogState extends State<_CreateComplaintDialog> {
  final _form = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  bool _busy = false;
  bool _failed = false;
  late final String _sessionIdentity;

  @override
  void initState() {
    super.initState();
    _sessionIdentity = widget.controller.access.sessionIdentity;
    widget.controller.addListener(_checkSession);
  }

  bool get _sameSession =>
      widget.controller.access.sessionIdentity == _sessionIdentity &&
      widget.controller.access.canCreate &&
      !widget.controller.sessionExpired;

  void _checkSession() {
    if (_sameSession) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.pop(context, false);
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkSession);
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_sameSession) {
      Navigator.pop(context, false);
      return;
    }
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final success = await widget.controller.create(
      _subject.text.trim(),
      _description.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return PopScope(
      canPop: !_busy,
      child: Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    strings.text('createTitle'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(strings.text('createBody')),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const ValueKey('complaint-subject'),
                    controller: _subject,
                    enabled: !_busy,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: strings.text('subjectLabel'),
                      hintText: strings.text('subjectHint'),
                    ),
                    validator: (value) => value?.trim().isNotEmpty == true
                        ? null
                        : strings.text('requiredSubject'),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const ValueKey('complaint-description'),
                    controller: _description,
                    enabled: !_busy,
                    minLines: 5,
                    maxLines: 12,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      labelText: strings.text('descriptionLabel'),
                      alignLabelWithHint: true,
                      hintText: strings.text('descriptionHint'),
                    ),
                    validator: (value) => value?.trim().isNotEmpty == true
                        ? null
                        : strings.text('requiredDescription'),
                  ),
                  const SizedBox(height: 16),
                  _InlineFeedback(message: strings.text('privateNotice')),
                  if (_failed) ...[
                    const SizedBox(height: 12),
                    _InlineFeedback(
                      message: strings.text('mutationError'),
                      isError: true,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.pop(context, false),
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
          ),
        ),
      ),
    );
  }
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent({
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: ComplaintPalette.of(context).muted),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    ),
  );
}

class _InlineFeedback extends StatelessWidget {
  const _InlineFeedback({
    required this.message,
    this.isError = false,
    this.action,
  });
  final String message;
  final bool isError;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = ComplaintPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isError ? colors.errorBackground : colors.infoBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.lock_outline,
                  size: 20,
                  color: isError ? colors.error : colors.info,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: isError ? colors.error : colors.info),
                  ),
                ),
              ],
            ),
            if (action != null) ...[const SizedBox(height: 8), action!],
          ],
        ),
      ),
    );
  }
}
