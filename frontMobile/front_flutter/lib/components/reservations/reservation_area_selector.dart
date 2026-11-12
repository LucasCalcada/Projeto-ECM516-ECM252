import 'package:flutter/material.dart';
import '../../lang/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../types/reservation.dart';

class ReservationAreaSelector extends StatelessWidget {
  const ReservationAreaSelector({super.key, required this.areas, required this.selectedId, required this.onChanged, this.enabled = true});
  final List<ReservationCommonArea> areas;
  final String? selectedId;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    ReservationCommonArea? selected;
    for (final area in areas) {
      if (area.id == selectedId) selected = area;
    }
    return Align(alignment: Alignment.centerLeft, child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(strings.text('reservations.area'), style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 4),
      InputDecorator(
        decoration: InputDecoration(enabled: enabled, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          key: const Key('reservation-area'),
          value: selectedId,
          isExpanded: true,
          isDense: false,
          itemHeight: null,
          dropdownColor: HiveColors.raised,
          items: [for (final area in areas) DropdownMenuItem(value: area.id,
            child: Text(area.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          )],
          onChanged: enabled ? (value) { if (value != null) onChanged(value); } : null,
        )),
      ),
      if (selected != null) ...[
        const SizedBox(height: 8),
        Text('${strings.text('reservations.capacity')}: ${selected.limit}', style: Theme.of(context).textTheme.bodySmall),
      ],
    ])));
  }
}
