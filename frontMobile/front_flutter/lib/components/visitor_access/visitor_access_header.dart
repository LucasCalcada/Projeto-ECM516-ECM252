import 'package:flutter/material.dart';

import '../../lang/app_localizations.dart';
import '../../theme/app_theme.dart';

enum VisitorAccessMode { create, view }

class VisitorAccessHeader extends StatelessWidget {
  const VisitorAccessHeader({
    super.key,
    required this.activeMode,
    required this.options,
    required this.onModeChange,
  });

  final VisitorAccessMode activeMode;
  final List<VisitorAccessMode> options;
  final ValueChanged<VisitorAccessMode> onModeChange;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final title = Row(
      children: [
        Icon(_icon(activeMode), color: HiveColors.primary, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              strings.text('visitorAccess.views.${activeMode.name}.title'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
      ],
    );
    if (options.length < 2) {
      return Padding(padding: const EdgeInsets.only(bottom: 24), child: title);
    }
    final modes = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final mode in options)
          _ModeButton(
            mode: mode,
            selected: mode == activeMode,
            label: strings.text('visitorAccess.views.${mode.name}.label'),
            onPressed: () => onModeChange(mode),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 768) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 12), modes],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: title),
              const SizedBox(width: 12),
              modes,
            ],
          );
        },
      ),
    );
  }
}

IconData _icon(VisitorAccessMode mode) => switch (mode) {
  VisitorAccessMode.create => Icons.person_add_outlined,
  VisitorAccessMode.view => Icons.checklist,
};

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.mode,
    required this.selected,
    required this.label,
    required this.onPressed,
  });

  final VisitorAccessMode mode;
  final bool selected;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: FilledButton.icon(
        key: Key('visitor-mode-${mode.name}'),
        onPressed: onPressed,
        icon: Icon(_icon(mode), size: 16),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: selected ? HiveColors.primary : HiveColors.raised,
          foregroundColor: selected ? HiveColors.canvas : HiveColors.text,
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
