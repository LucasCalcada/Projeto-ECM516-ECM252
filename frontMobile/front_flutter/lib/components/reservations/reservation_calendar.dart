import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../lang/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../types/reservation.dart';

class ReservationCalendar extends StatefulWidget {
  const ReservationCalendar({super.key, required this.reservations, required this.selectedDate, required this.onSelect, this.enabled = true});
  final List<Reservation> reservations;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelect;
  final bool enabled;

  @override
  State<ReservationCalendar> createState() => _ReservationCalendarState();
}

class _ReservationCalendarState extends State<ReservationCalendar> {
  late DateTime _month;
  @override
  void initState() {
    super.initState();
    final now = widget.selectedDate ?? reservationToday();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final locale = MaterialLocalizations.of(context);
    final today = reservationToday();
    final occupied = widget.reservations.map((item) => reservationDateString(item.date)).toSet();
    final firstWeekday = locale.firstDayOfWeekIndex;
    final leading = (_month.weekday % 7 - firstWeekday + 7) % 7;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final dayStyle = Theme.of(context).textTheme.labelLarge;
    final dayLineHeight = MediaQuery.textScalerOf(context)
        .scale(dayStyle?.fontSize ?? 14) * (dayStyle?.height ?? 20 / 14);
    // Keep compact days while allowing enlarged text and the occupied icon.
    final cellHeight = math.max(44.0, dayLineHeight + 24);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        IconButton(tooltip: strings.text('reservations.calendar.previousMonth'),
          onPressed: widget.enabled ? () => setState(() => _month = DateTime(_month.year, _month.month - 1)) : null,
          icon: const Icon(Icons.chevron_left)),
        Expanded(child: Semantics(header: true, liveRegion: true, child: Text(locale.formatMonthYear(_month), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium))),
        IconButton(tooltip: strings.text('reservations.calendar.nextMonth'),
          onPressed: widget.enabled ? () => setState(() => _month = DateTime(_month.year, _month.month + 1)) : null,
          icon: const Icon(Icons.chevron_right)),
      ]),
      const SizedBox(height: 8),
      Column(children: [
          Row(children: [for (var i = 0; i < 7; i++) Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(locale.narrowWeekdays[(firstWeekday + i) % 7], textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelMedium),
          ))]),
          GridView.builder(
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: cellHeight, crossAxisSpacing: 4, mainAxisSpacing: 4),
            itemCount: leading + days,
            itemBuilder: (context, index) {
              if (index < leading) return const SizedBox.shrink();
              final date = DateTime(_month.year, _month.month, index - leading + 1);
              final reserved = occupied.contains(reservationDateString(date));
              final past = date.isBefore(today);
              final selected = widget.selectedDate != null && reservationDateString(widget.selectedDate!) == reservationDateString(date);
              final status = strings.text(past ? 'reservations.calendar.past' : reserved ? 'reservations.calendar.reserved' : 'reservations.calendar.available');
              return Semantics(
                label: '${locale.formatFullDate(date)}, $status',
                selected: selected,
                child: Tooltip(message: status, child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: TextButton(
                    key: ValueKey('reservation-day-${reservationDateString(date)}'),
                    onPressed: widget.enabled && !past && !reserved ? () => widget.onSelect(date) : null,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero, padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: past ? HiveColors.divider : selected && !reserved ? HiveColors.primary : HiveColors.canvas,
                      foregroundColor: selected && !past && !reserved ? HiveColors.canvas : HiveColors.text,
                      disabledForegroundColor: past ? HiveColors.text : HiveColors.secondary,
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('${date.day}'),
                      if (reserved) const Icon(Icons.event_busy_outlined, size: 16),
                    ]),
                  ),
                )),
              );
            },
          ),
        ]),
      const SizedBox(height: 12),
      Wrap(spacing: 16, runSpacing: 8, children: [
        Text(strings.text('reservations.calendar.available')),
        Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.event_busy_outlined, size: 16), const SizedBox(width: 4), Flexible(child: Text(strings.text('reservations.calendar.reserved')))]),
      ]),
    ]);
  }
}
