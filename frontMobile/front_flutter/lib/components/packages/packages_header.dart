import 'package:flutter/material.dart';

import '../../lang/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'package_view_mode.dart';

class PackagesHeader extends StatelessWidget {
  const PackagesHeader({
    super.key,
    required this.activeMode,
    required this.options,
    required this.onModeChange,
  });

  final PackageViewMode activeMode;
  final List<PackageViewOption> options;
  final ValueChanged<PackageViewMode> onModeChange;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(activeMode.icon, size: 22, color: HiveColors.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(
                    strings.text('${activeMode.key}.title'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ],
          ),
          // The mode selector only exists when more than one view is allowed.
          if (options.length > 1)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options)
                  _ModeButton(
                    mode: option.mode,
                    label: strings.text('${option.mode.key}.label'),
                    active: option.mode == activeMode,
                    onPressed: () => onModeChange(option.mode),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.mode,
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final PackageViewMode mode;
  final String label;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: active,
      button: true,
      child: TextButton.icon(
        key: ValueKey('packages-mode-${mode.name}'),
        onPressed: onPressed,
        icon: Icon(mode.icon, size: 16),
        label: Text(label),
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            active ? colors.primary : HiveColors.raised,
          ),
          foregroundColor: WidgetStatePropertyAll(
            active ? colors.onPrimary : colors.onSurface,
          ),
        ),
      ),
    );
  }
}
