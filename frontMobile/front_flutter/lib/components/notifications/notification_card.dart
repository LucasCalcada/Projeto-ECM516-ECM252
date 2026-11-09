import 'package:flutter/material.dart';

import '../../lang/app_localizations.dart';
import '../../types/communication_post.dart';
import '../home/post_content.dart';
import 'audience_chip.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.post,
    this.residencyNames,
    this.onDelete,
    this.deleting = false,
  });

  final CommunicationPost post;
  final Map<String, String>? residencyNames;
  final VoidCallback? onDelete;
  final bool deleting;

  String _dateTime(BuildContext context, DateTime value) {
    final material = MaterialLocalizations.of(context);
    final time = material.formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return '${material.formatMediumDate(value)} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AudienceChip(post: post, residencyNames: residencyNames),
                if (post.eventAt != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _dateTime(context, post.eventAt!),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            PostContent(key: ValueKey('content-${post.id}'), post: post),
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.format('notifications.sentAt', {
                      'date': _dateTime(context, post.createdAt),
                    }),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (onDelete != null)
                  TextButton.icon(
                    key: ValueKey('delete-${post.id}'),
                    onPressed: deleting ? null : onDelete,
                    style: TextButton.styleFrom(foregroundColor: colors.error),
                    icon: deleting
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline, size: 18),
                    label: Text(strings.text('notifications.delete')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
