import 'package:flutter/material.dart';

import '../../lang/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../types/delivery_package.dart';

/// Status is always conveyed by label and icon in addition to color.
class PackageStatusBadge extends StatelessWidget {
  const PackageStatusBadge({super.key, required this.status});

  final DeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final color = switch (status) {
      DeliveryStatus.pending => HiveColors.warning,
      DeliveryStatus.delivered => HiveColors.success,
      _ => HiveColors.secondary,
    };
    final icon = switch (status) {
      DeliveryStatus.pending => Icons.schedule,
      DeliveryStatus.delivered => Icons.check_circle_outline,
      DeliveryStatus.canceled => Icons.cancel_outlined,
      DeliveryStatus.unknown => Icons.help_outline,
    };
    final label = status == DeliveryStatus.unknown
        ? strings.text('packages.statusValue.UNKNOWN')
        : strings.text('packages.statusValue.${status.value}');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HiveColors.raised,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
