import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../types/complaint.dart';
import '../../lang/complaint_strings.dart';
import 'complaint_feedback.dart';
import 'complaint_status_badge.dart';

class ComplaintList extends StatelessWidget {
  const ComplaintList({
    super.key,
    required this.strings,
    required this.items,
    required this.loadFailed,
    required this.loading,
    required this.loadingMore,
    required this.filtered,
    required this.busy,
    required this.hasMore,
    required this.expandedId,
    required this.detail,
    required this.onSelect,
    required this.onLoadMore,
  });
  final ComplaintStrings strings;
  final List<Complaint> items;
  final bool loadFailed;
  final bool loading;
  final bool loadingMore;
  final bool filtered;
  final bool busy;
  final bool hasMore;
  final String? expandedId;
  final Widget detail;
  final ValueChanged<Complaint> onSelect;
  final VoidCallback onLoadMore;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && loadFailed) {
      return const SizedBox.shrink();
    }
    if (loading && items.isEmpty) {
      return complaintEmpty(strings.text('loading'), '', loading: true);
    }
    if (items.isEmpty) {
      return complaintEmpty(
        strings.text(filtered ? 'filteredEmpty' : 'emptyTitle'),
        loadFailed ? strings.text('loadError') : strings.text('emptyBody'),
      );
    }
    return Column(
      key: const ValueKey('complaint-list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items) ...[
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
                  expanded: expandedId == item.id,
                  child: InkWell(
                    key: ValueKey('complaint-toggle-${item.id}'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: busy ? null : () => onSelect(item),
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
                                expandedId == item.id
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
                              ComplaintStatusBadge(
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
                if (expandedId == item.id) ...[
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
                    child: detail,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (hasMore)
          TextButton(
            onPressed: loadingMore || busy ? null : onLoadMore,
            child: Text(strings.text(loadingMore ? 'loading' : 'loadMore')),
          ),
      ],
    );
  }
}
