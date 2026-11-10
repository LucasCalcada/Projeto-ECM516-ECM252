import 'package:flutter/material.dart';

import '../../lang/app_localizations.dart';
import '../../types/residency_group.dart';

/// Checkbox list of residencies grouped by tower or block.
class ResidencyPicker extends StatelessWidget {
  const ResidencyPicker({
    super.key,
    required this.groups,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final List<ResidencyGroup> groups;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool enabled;

  void _toggle(String id) {
    final next = {...selected};
    if (!next.remove(id)) next.add(id);
    onChanged(next);
  }

  void _toggleGroup(ResidencyGroup group) {
    final ids = group.residencies.map((residency) => residency.id);
    final allSelected = ids.every(selected.contains);
    final next = {...selected};
    allSelected ? next.removeAll(ids) : next.addAll(ids);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (groups.isEmpty) {
      return Text(strings.text('notifications.form.noResidencies'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          key: ValueKey('toggle-group-${group.id}'),
                          onPressed: enabled ? () => _toggleGroup(group) : null,
                          child: Text(
                            strings.text(
                              group.residencies.every(
                                    (residency) =>
                                        selected.contains(residency.id),
                                  )
                                  ? 'notifications.form.clearGroup'
                                  : 'notifications.form.selectGroup',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final residency in group.residencies)
                    CheckboxListTile(
                      key: ValueKey('residency-${residency.id}'),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(residency.name),
                      value: selected.contains(residency.id),
                      onChanged: enabled ? (_) => _toggle(residency.id) : null,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
