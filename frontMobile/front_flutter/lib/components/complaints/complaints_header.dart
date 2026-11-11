import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../types/complaint.dart';
import '../../lang/complaint_strings.dart';

class ComplaintsHeader extends StatelessWidget {
  const ComplaintsHeader({
    super.key,
    required this.strings,
    required this.buildingName,
    required this.showCreate,
    required this.scopes,
    required this.selectedScope,
    required this.canCreate,
    required this.busy,
    required this.loading,
    required this.onScope,
    required this.onCreate,
    required this.onRefresh,
  });
  final ComplaintStrings strings;
  final String? buildingName;
  final bool showCreate;
  final List<ComplaintScope> scopes;
  final ComplaintScope selectedScope;
  final bool canCreate;
  final bool busy;
  final bool loading;
  final ValueChanged<ComplaintScope> onScope;
  final VoidCallback onCreate;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) => Column(
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
      if (buildingName?.isNotEmpty == true) ...[
        const SizedBox(height: 8),
        Text(
          buildingName!,
          style: const TextStyle(color: HiveColors.secondary),
        ),
      ],
      if (!showCreate) ...[
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (scopes.length > 1)
              for (final scope in scopes)
                FilledButton.tonal(
                  onPressed: busy ? null : () => onScope(scope),
                  style:
                      FilledButton.styleFrom(
                        backgroundColor: selectedScope == scope
                            ? HiveColors.primary
                            : HiveColors.raised,
                        foregroundColor: selectedScope == scope
                            ? HiveColors.canvas
                            : HiveColors.text,
                      ).copyWith(
                        side: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.focused)
                              ? BorderSide(
                                  color: selectedScope == scope
                                      ? HiveColors.canvas
                                      : HiveColors.primary,
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                      ),
                  child: Semantics(
                    selected: selectedScope == scope,
                    child: Text(strings.text(scope.name)),
                  ),
                ),
            if (canCreate)
              FilledButton.icon(
                key: const ValueKey('new-complaint'),
                onPressed: busy ? null : onCreate,
                icon: const Icon(Icons.add, size: 16),
                label: Text(strings.text('newComplaint')),
              ),
            TextButton.icon(
              onPressed: loading || busy ? null : onRefresh,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(strings.text('refresh')),
            ),
          ],
        ),
      ],
    ],
  );
}
