import 'package:flutter/material.dart';

import 'features/complaints/complaints.dart';
import 'features/complaints/preview/demo_complaints_repository.dart';

/// Separate visual preview. The application's existing main.dart is untouched.
void main() => runApp(const ComplaintsPreview());

class ComplaintsPreview extends StatefulWidget {
  const ComplaintsPreview({super.key});

  @override
  State<ComplaintsPreview> createState() => _ComplaintsPreviewState();
}

class _ComplaintsPreviewState extends State<ComplaintsPreview> {
  String _profile = 'resident';
  String _scenario = 'data';
  String _language = 'pt';
  bool _dark = true;
  int _revision = 0;
  late DemoComplaintsRepository _repository;
  late ComplaintAccess _access;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _repository = DemoComplaintsRepository();
    if (_scenario == 'empty') _repository.clear();
    if (_scenario == 'error') _repository.failNextRead = true;
    _access = switch (_profile) {
      'signedOut' => const ComplaintAccess.signedOut(),
      'denied' => const ComplaintAccess.denied(),
      _ => ComplaintAccess.fromSession(
        userId: 'preview-$_profile',
        buildingId: 'preview-building',
        permissions: _profile == 'manager' ? ['@complaint:manage'] : const [],
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    };
    _revision++;
  }

  void _change(VoidCallback change) => setState(() {
    change();
    _reset();
  });

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'HiveApp — prévia de reclamações',
    theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
    darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
    themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
    home: Scaffold(
      appBar: AppBar(
        title: const Text('Prévia visual · dados de demonstração'),
        actions: [
          IconButton(
            tooltip: _dark ? 'Ativar tema claro' : 'Ativar tema escuro',
            onPressed: () => setState(() => _dark = !_dark),
            icon: Icon(_dark ? Icons.light_mode_outlined : Icons.dark_mode),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _choice(
                  label: 'Perfil da demonstração',
                  value: _profile,
                  entries: const {
                    'resident': 'Morador',
                    'manager': 'Administração',
                    'signedOut': 'Sem sessão',
                    'denied': 'Sem acesso',
                  },
                  onChanged: (value) => _change(() => _profile = value),
                ),
                _choice(
                  label: 'Estado da demonstração',
                  value: _scenario,
                  entries: const {
                    'data': 'Com registros',
                    'empty': 'Sem registros',
                    'error': 'Falha de leitura',
                  },
                  onChanged: (value) => _change(() => _scenario = value),
                ),
                _choice(
                  label: 'Idioma da interface',
                  value: _language,
                  entries: const {
                    'pt': 'Português',
                    'en': 'English',
                    'es': 'Español',
                  },
                  onChanged: (value) => setState(() => _language = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: ComplaintsScreen(
              key: ValueKey(_revision),
              access: _access,
              repository: _repository,
              buildingName: 'Condomínio de exemplo',
              languageCode: _language,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _choice({
    required String label,
    required String value,
    required Map<String, String> entries,
    required ValueChanged<String> onChanged,
  }) => SizedBox(
    width: 220,
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: InputBorder.none),
      items: [
        for (final entry in entries.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    ),
  );
}
