import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../helpers/complaints_controller.dart';
import '../helpers/complaint_access.dart';
import '../helpers/complaints_repository.dart';
import '../types/complaint.dart';
import '../lang/complaint_strings.dart';
import '../components/complaints/complaints_header.dart';
import '../components/complaints/complaints_filters.dart';
import '../components/complaints/complaint_list.dart';
import '../components/complaints/complaint_detail.dart';
import '../components/complaints/complaint_create_form.dart';
import '../components/complaints/complaint_feedback.dart';
import '../components/complaints/complaint_confirmation_dialog.dart';

/// Bridges shell navigation to the mounted view without exposing widget State.
class ComplaintsNavigationController {
  Future<bool> Function()? _beforeLeave;
  Future<bool> Function()? _back;
  Future<bool> confirmLeave() => _beforeLeave?.call() ?? Future.value(true);
  Future<bool> handleBack() => _back?.call() ?? Future.value(false);
  void _bind(
    Future<bool> Function() beforeLeave,
    Future<bool> Function() back,
  ) {
    _beforeLeave = beforeLeave;
    _back = back;
  }

  void _unbind() {
    _beforeLeave = null;
    _back = null;
  }
}

class ComplaintsView extends StatefulWidget {
  const ComplaintsView({
    required this.access,
    required this.repository,
    this.buildingName,
    this.strings,
    this.navigation,
    this.onSessionExpired,
    this.onSignIn,
    this.shellManaged = false,
    super.key,
  });
  final ComplaintAccess access;
  final ComplaintsRepository repository;
  final String? buildingName;
  final ComplaintStrings? strings;
  final ComplaintsNavigationController? navigation;
  final VoidCallback? onSessionExpired;
  final VoidCallback? onSignIn;
  final bool shellManaged;

  @override
  State<ComplaintsView> createState() => _ComplaintsViewState();
}

class _ComplaintsViewState extends State<ComplaintsView> {
  late ComplaintsController _controller;
  Timer? _expiry;
  bool _showDetail = false;
  bool _showCreate = false;
  bool _dirty = false;
  bool _expiryNotified = false;
  Future<bool>? _leaveRequest;
  ComplaintStrings get _strings =>
      widget.strings ?? ComplaintStrings.of(context);

  @override
  void initState() {
    super.initState();
    _initialize();
    _bindNavigation();
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
  void didUpdateWidget(covariant ComplaintsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigation != widget.navigation) {
      oldWidget.navigation?._unbind();
      _bindNavigation();
    }
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
    widget.navigation?._unbind();
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

  void _bindNavigation() {
    widget.navigation?._bind(confirmLeave, handleShellBack);
  }

  Future<void> _create() async {
    if (!await confirmLeave() || !mounted) return;
    setState(() {
      _showCreate = true;
      _showDetail = false;
      _dirty = false;
    });
    _controller.clearSelection();
  }

  Future<bool> _close(bool hasDraft) async {
    final id = _controller.selected?.id;
    final identity = _controller.access.sessionIdentity;
    if (id == null ||
        !await _confirm(
          context,
          _strings,
          _controller,
          title: 'closeTitle',
          body: hasDraft ? 'closeBodyWithDraft' : 'closeBody',
          action: 'confirmClose',
          complaintId: id,
        )) {
      return false;
    }
    if (!mounted ||
        _controller.selected?.id != id ||
        _controller.access.sessionIdentity != identity) {
      return false;
    }
    return _controller.close();
  }

  Future<bool> _confirm(
    BuildContext context,
    ComplaintStrings strings,
    ComplaintsController controller, {
    required String title,
    required String body,
    required String action,
    String? complaintId,
  }) {
    final identity = controller.access.sessionIdentity;
    return showComplaintConfirmation(
      context,
      strings,
      controller,
      title: title,
      body: body,
      action: action,
      isValid: () =>
          !controller.sessionExpired &&
          controller.access.canAccess &&
          controller.access.sessionIdentity == identity &&
          (complaintId == null || controller.selected?.id == complaintId),
    );
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
            return complaintEmpty(
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
                        ComplaintsHeader(
                          strings: strings,
                          buildingName: widget.buildingName,
                          showCreate: _showCreate,
                          scopes: ComplaintScope.values
                              .where(_controller.access.canReadScope)
                              .toList(),
                          selectedScope: _controller.scope,
                          canCreate: _controller.access.canCreate,
                          busy: _controller.isSubmitting,
                          loading: _controller.isLoading,
                          onScope: _scope,
                          onCreate: _create,
                          onRefresh: () => _controller.load(),
                        ),
                        const SizedBox(height: 24),
                        if (_showCreate)
                          ComplaintCreateForm(
                            key: ValueKey(
                              'create-${widget.access.sessionIdentity}',
                            ),
                            onCreate:
                                (title, description, {required category}) =>
                                    _controller.create(
                                      title,
                                      description,
                                      category: category,
                                    ),
                            mutationFailure: _controller.mutationFailure,
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
                          complaintEmpty(
                            strings.text('deniedTitle'),
                            strings.text('deniedBody'),
                          )
                        else ...[
                          ComplaintsFilters(
                            strings: strings,
                            status: _controller.statusFilter,
                            category: _controller.categoryFilter,
                            busy: _controller.isSubmitting,
                            onStatus: (value) => _filter(
                              status: value,
                              category: _controller.categoryFilter,
                            ),
                            onCategory: (value) => _filter(
                              status: _controller.statusFilter,
                              category: value,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_controller.loadFailed) ...[
                            complaintFeedback(
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
                          ComplaintList(
                            strings: strings,
                            items: _controller.items,
                            loadFailed: _controller.loadFailed,
                            loading: _controller.isLoading,
                            loadingMore: _controller.isLoadingMore,
                            filtered:
                                _controller.statusFilter != null ||
                                _controller.categoryFilter != null,
                            busy: _controller.isSubmitting,
                            hasMore: _controller.hasMore,
                            expandedId: _showDetail
                                ? _controller.selected?.id
                                : null,
                            detail: _detail(context, strings),
                            onSelect: _select,
                            onLoadMore: () => _controller.load(more: true),
                          ),
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

  Widget _detail(BuildContext context, ComplaintStrings strings) {
    final selected = _controller.selected;
    if (_controller.isDetailLoading && selected?.hasDetails != true) {
      return complaintEmpty(strings.text('loading'), '', loading: true);
    }
    if (_controller.detailFailure != null && selected?.hasDetails != true) {
      return complaintFeedback(
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
      return complaintEmpty(
        strings.text('selectTitle'),
        strings.text('selectBody'),
      );
    }
    return ComplaintDetail(
      key: ValueKey('${widget.access.sessionIdentity}:${selected.id}'),
      complaint: selected,
      busy: _controller.isSubmitting || _controller.isDetailLoading,
      loading: _controller.isDetailLoading,
      canAct: _controller.canAct,
      canRespond: _controller.canRespond,
      canChangeStatus: _controller.canChangeStatus,
      mutationFailure: _controller.mutationFailure,
      onRespond: _controller.respond,
      onChangeStatus: _controller.changeStatus,
      onClose: _close,
      strings: strings,
      onSuccess: _notify,
      onDirty: _draft,
    );
  }
}
