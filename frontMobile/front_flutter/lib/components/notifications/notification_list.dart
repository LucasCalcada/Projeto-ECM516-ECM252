import 'package:flutter/material.dart';

import '../../helpers/communication_service.dart';
import '../../helpers/core_service.dart';
import '../../lang/app_localizations.dart';
import '../../types/api_failure.dart';
import '../../types/communication_post.dart';
import '../../types/user_session.dart';
import '../shared/request_feedback.dart';
import 'notification_card.dart';

/// Lists notifications. With [manage] it shows every notification of the
/// building, the residencies they target and a delete action.
class NotificationList extends StatefulWidget {
  const NotificationList({
    super.key,
    required this.service,
    required this.coreService,
    required this.session,
    required this.onSessionExpired,
    this.manage = false,
  });

  final CommunicationService service;
  final CoreService coreService;
  final UserSession session;
  final VoidCallback onSessionExpired;
  final bool manage;

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  List<CommunicationPost>? _posts;
  Map<String, String>? _residencyNames;
  bool _loading = false;
  ApiFailure? _error;
  String? _deletingId;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.manage) _loadResidencyNames();
  }

  ApiFailure _failure(Object error) =>
      error is ApiException ? error.failure : ApiFailure.unexpected;

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = widget.manage
          ? await widget.service.listBuildingPosts(widget.session)
          : await widget.service.listPosts(widget.session);
      if (mounted) setState(() => _posts = posts);
    } catch (error) {
      if (!mounted) return;
      final failure = _failure(error);
      if (failure == ApiFailure.unauthorized) {
        widget.onSessionExpired();
      } else {
        setState(() => _error = failure);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Names are cosmetic: on failure the chips fall back to a generic label.
  Future<void> _loadResidencyNames() async {
    try {
      final groups = await widget.coreService.listResidencies(widget.session);
      if (!mounted) return;
      setState(() {
        _residencyNames = {
          for (final group in groups)
            for (final residency in group.residencies)
              residency.id: residency.name,
        };
      });
    } catch (_) {}
  }

  Future<void> _delete(CommunicationPost post) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.text('notifications.deleteTitle')),
        content: Text(
          strings.format('notifications.deleteMessage', {'title': post.title}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.text('notifications.cancel')),
          ),
          TextButton(
            key: const Key('confirm-delete'),
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(strings.text('notifications.delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deletingId = post.id);
    try {
      await widget.service.deletePost(widget.session, post.id);
      if (!mounted) return;
      setState(() {
        _posts = _posts?.where((item) => item.id != post.id).toList();
      });
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(strings.text('notifications.deleted'))),
      );
    } catch (error) {
      if (!mounted) return;
      final failure = _failure(error);
      if (failure == ApiFailure.unauthorized) {
        widget.onSessionExpired();
      } else {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(strings.error(failure))));
      }
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final posts = _posts;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        key: PageStorageKey('notifications-${widget.manage}'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('refresh-notifications'),
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
              label: Text(strings.text('refresh')),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) RequestFeedback(failure: _error, onRetry: _load),
          if (posts != null && posts.isEmpty)
            RequestFeedback(message: strings.text('notifications.empty')),
          if (posts != null)
            for (final post in posts)
              NotificationCard(
                key: ValueKey(post.id),
                post: post,
                residencyNames: widget.manage ? _residencyNames ?? {} : null,
                onDelete: widget.manage ? () => _delete(post) : null,
                deleting: _deletingId == post.id,
              ),
        ],
      ),
    );
  }
}
