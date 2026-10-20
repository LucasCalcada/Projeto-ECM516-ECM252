import 'package:flutter/material.dart';

import '../../lang/app_localizations.dart';

class EventDateBadge extends StatelessWidget {
  const EventDateBadge({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) => Semantics(
    label: MaterialLocalizations.of(context).formatFullDate(date),
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context).month(date.month).toUpperCase()),
          Text(
            date.day.toString().padLeft(2, '0'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text('${date.year}', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}
