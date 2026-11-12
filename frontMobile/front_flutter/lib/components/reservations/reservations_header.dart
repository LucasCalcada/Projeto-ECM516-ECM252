import 'package:flutter/material.dart';
import '../../lang/app_localizations.dart';
import '../../theme/app_theme.dart';

enum ReservationMode { create, building, residency }

class ReservationsHeader extends StatelessWidget {
  const ReservationsHeader({super.key, required this.mode, required this.options, required this.onModeChanged, this.busy = false});
  final ReservationMode mode;
  final List<ReservationMode> options;
  final ValueChanged<ReservationMode> onModeChanged;
  final bool busy;

  static IconData icon(ReservationMode mode) => switch (mode) {
    ReservationMode.create => Icons.event_available_outlined,
    ReservationMode.building => Icons.apartment_outlined,
    ReservationMode.residency => Icons.home_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon(mode), color: HiveColors.primary, size: 24),
          const SizedBox(width: 8),
          Expanded(child: Semantics(header: true, child: Text(strings.text('reservations.views.${mode.name}.title'), style: Theme.of(context).textTheme.headlineSmall))),
        ]),
        const SizedBox(height: 8),
        Text(strings.text('reservations.views.${mode.name}.description')),
        if (options.length > 1) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final option in options)
            Semantics(selected: mode == option, child: FilledButton.icon(
              key: Key('reservation-mode-${option.name}'),
              onPressed: busy ? null : () => onModeChanged(option),
              icon: Icon(icon(option), size: 16),
              label: Text(strings.text('reservations.views.${option.name}.label')),
              style: FilledButton.styleFrom(backgroundColor: mode == option ? HiveColors.primary : HiveColors.raised,
                foregroundColor: mode == option ? HiveColors.canvas : HiveColors.text),
            )),
          ]),
        ],
      ]),
    );
  }
}
