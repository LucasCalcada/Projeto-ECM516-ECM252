import 'package:flutter/material.dart';

import '../../lang/app_localizations.dart';
import '../../types/communication_post.dart';

/// Shows who receives a notification: the whole building or residencies.
class AudienceChip extends StatelessWidget {
  const AudienceChip({super.key, required this.post, this.residencyNames});

  final CommunicationPost post;

  /// Resolves residency IDs to names. Without it, residency notifications are
  /// labelled as addressed to the reader's own residency.
  final Map<String, String>? residencyNames;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final names = residencyNames;
    final String label;
    if (post.isBuildingWide) {
      label = strings.text('notifications.audience.building');
    } else if (names == null) {
      label = strings.text('notifications.audience.myResidency');
    } else {
      label = post.residencyIds
          .map(
            (id) =>
                names[id] ??
                strings.text('notifications.audience.unknownResidency'),
          )
          .join(', ');
    }
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF404040)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            post.isBuildingWide
                ? Icons.apartment_outlined
                : Icons.home_outlined,
            size: 14,
            color: colors.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
