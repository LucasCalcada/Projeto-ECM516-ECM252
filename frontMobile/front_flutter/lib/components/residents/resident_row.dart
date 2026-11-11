import 'package:flutter/material.dart';

import '../../lang/app_localizations.dart';
import '../../types/resident.dart';

class ResidentRow extends StatelessWidget {
  const ResidentRow({super.key, required this.resident, required this.onEdit});
  final Resident resident;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final name = resident.name.isEmpty ? strings.text('residents.unnamedResident') : resident.name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        const Icon(Icons.person_outline, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(name)),
        IconButton(
          key: ValueKey('resident-edit-${resident.id}'),
          tooltip: '${strings.text('residents.edit')}: $name',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 20),
        ),
      ]),
    );
  }
}
