import 'package:flutter/material.dart';

import '../../lang/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../types/communication_post.dart';
import '../shared/request_feedback.dart';
import 'event_date_badge.dart';

/// Home-specific panel exception documented in audit/design-system.md, DS-05.
const homeListDecoration = BoxDecoration(
  color: HiveColors.surface,
  border: Border.fromBorderSide(BorderSide(color: HiveColors.divider)),
  borderRadius: BorderRadius.all(Radius.circular(8)),
);

class PostsSectionHeader extends StatelessWidget {
  const PostsSectionHeader({super.key, required this.events});
  final bool events;

  @override
  Widget build(BuildContext context) => Padding(
    key: ValueKey(
      events ? 'home-events-heading' : 'home-announcements-heading',
    ),
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Icon(events ? Icons.calendar_month_outlined : Icons.campaign_outlined),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            AppLocalizations.of(context)
                .text(events ? 'home.events' : 'home.announcements'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    ),
  );
}

/// Reuses the same lazy list in the mobile page and independent desktop columns.
class PostsSection extends StatelessWidget {
  const PostsSection({
    super.key,
    required this.posts,
    required this.events,
    required this.expandedPosts,
    required this.onTogglePost,
    this.showHeader = true,
  });

  final List<CommunicationPost> posts;
  final bool events;
  final bool showHeader;
  final Set<String> expandedPosts;
  final ValueChanged<String> onTogglePost;

  @override
  Widget build(BuildContext context) {
    final headerCount = showHeader ? 1 : 0;
    return SliverList.builder(
      itemCount: headerCount + (posts.isEmpty ? 1 : posts.length),
      itemBuilder: (context, index) {
        if (showHeader && index == 0) return PostsSectionHeader(events: events);
        if (posts.isEmpty) {
          return RequestFeedback(
            message: AppLocalizations.of(context)
                .text(events ? 'home.noEvents' : 'home.noAnnouncements'),
          );
        }
        final post = posts[index - headerCount];
        return _PostCard(
          key: ValueKey(post.id),
          post: post,
          expanded: expandedPosts.contains(post.id),
          onToggle: () => onTogglePost(post.id),
        );
      },
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({
    super.key,
    required this.post,
    required this.expanded,
    required this.onToggle,
  });
  final CommunicationPost post;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final eventAt = post.eventAt;
    final prefix = eventAt == null ? 'announcement' : 'event';
    return Card(
      key: ValueKey('home-post-surface-${post.id}'),
      color: HiveColors.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            key: ValueKey('$prefix-toggle-${post.id}'),
            button: true,
            expanded: widget.expanded,
            child: InkWell(
              onTap: widget.onToggle,
              onFocusChange: (focused) => setState(() => _focused = focused),
              child: Container(
                key: ValueKey('home-post-focus-${post.id}'),
                constraints: const BoxConstraints(minHeight: 48),
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    width: 2,
                    color: _focused ? HiveColors.primary : Colors.transparent,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            post.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(widget.expanded ? Icons.expand_less : Icons.expand_more),
                      ],
                    ),
                    if (eventAt != null) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          EventDateBadge(date: eventAt),
                          Text(
                            MaterialLocalizations.of(context).formatTimeOfDay(
                              TimeOfDay.fromDateTime(eventAt),
                              alwaysUse24HourFormat:
                                  MediaQuery.alwaysUse24HourFormatOf(context),
                            ),
                            key: ValueKey('event-time-${post.id}'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (widget.expanded)
            Padding(
              key: ValueKey('$prefix-details-${post.id}'),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eventAt == null) ...[
                    Text(
                      MaterialLocalizations.of(context).formatFullDate(post.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    post.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
