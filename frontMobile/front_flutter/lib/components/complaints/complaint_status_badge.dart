import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../types/complaint.dart';
import '../../lang/complaint_strings.dart';

class ComplaintStatusBadge extends StatelessWidget {
  const ComplaintStatusBadge({
    super.key,
    required this.status,
    required this.strings,
  });
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
