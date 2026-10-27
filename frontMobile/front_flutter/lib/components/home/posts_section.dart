import 'package:flutter/material.dart';

import '../../lang/app_localizations.dart';
import '../../types/communication_post.dart';
import '../shared/request_feedback.dart';
import 'event_date_badge.dart';
import 'post_content.dart';

/// A sliver keeps both sections in the same, lazily built page scroll.
class PostsSection extends StatelessWidget {
  const PostsSection({super.key, required this.posts, required this.events});

  final List<CommunicationPost> posts;
  final bool events;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return SliverList.builder(
      itemCount: 1 + (posts.isEmpty ? 1 : posts.length),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 12),
            child: Row(
              children: [
                Icon(
                  events
                      ? Icons.calendar_month_outlined
                      : Icons.campaign_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.text(events ? 'home.events' : 'home.announcements'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
          );
        }
        if (posts.isEmpty) {
          return RequestFeedback(
            message: strings.text(
              events ? 'home.noEvents' : 'home.noAnnouncements',
            ),
          );
        }
        final post = posts[index - 1];
        return Card(
          key: ValueKey(post.id),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (events) ...[
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      EventDateBadge(date: post.eventAt!),
                      Text(
                        MaterialLocalizations.of(context).formatTimeOfDay(
                          TimeOfDay.fromDateTime(post.eventAt!),
                          alwaysUse24HourFormat:
                              MediaQuery.alwaysUse24HourFormatOf(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Text(
                    MaterialLocalizations.of(context)
                        .formatFullDate(post.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                ],
                PostContent(key: ValueKey(post.id), post: post),
              ],
            ),
          ),
        );
      },
    );
  }
}
