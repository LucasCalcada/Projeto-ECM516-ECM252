import 'package:flutter/material.dart';

import '../../lang/app_localizations.dart';
import '../../types/user_session.dart';

class BuildingHeader extends StatelessWidget {
  const BuildingHeader({super.key, required this.session});

  final UserSession session;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 26,
          child: Icon(Icons.apartment_outlined, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          session.buildingName.isEmpty
              ? AppLocalizations.of(context).text('selector.unnamedBuilding')
              : session.buildingName,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (session.residencyName?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(session.residencyName!),
        ],
      ],
    ),
  );
}
