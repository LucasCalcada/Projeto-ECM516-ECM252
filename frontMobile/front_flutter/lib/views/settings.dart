import 'package:flutter/material.dart';

import '../components/shared/request_feedback.dart';
import '../lang/app_localizations.dart';
import '../types/api_failure.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onLanguageChanged});

  final Future<void> Function(String) onLanguageChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _saving = false;
  bool _failed = false;

  Future<void> _select(String language) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.onLanguageChanged(language);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(strings.text('settings.subtitle')),
            const SizedBox(height: 24),
            Text(
              strings.text('settings.language'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (_saving) const LinearProgressIndicator(),
            if (_failed) const RequestFeedback(failure: ApiFailure.storage),
            for (final entry in const {
              'pt': 'Português',
              'en': 'English',
              'es': 'Español',
            }.entries)
              Card(
                child: ListTile(
                  key: ValueKey('language-${entry.key}'),
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.language),
                  title: Text(entry.value),
                  subtitle: language == entry.key
                      ? Text(strings.text('settings.selected'))
                      : null,
                  trailing: language == entry.key
                      ? const Icon(Icons.check_circle)
                      : null,
                  selected: language == entry.key,
                  enabled: !_saving,
                  onTap: () => _select(entry.key),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
