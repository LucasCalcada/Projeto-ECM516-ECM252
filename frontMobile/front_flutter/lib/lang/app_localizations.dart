import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../types/api_failure.dart';

class AppLocalizations {
  const AppLocalizations(this.messages);

  final Map<String, dynamic> messages;
  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  String text(String key) => messages[key] as String;
  String error(ApiFailure failure) => text('errors.${failure.name}');
  String month(int month) => (messages['months'] as List)[month - 1] as String;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['pt', 'en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final source = await rootBundle.loadString(
      'lib/lang/${locale.languageCode}/app.json',
    );
    return AppLocalizations(jsonDecode(source) as Map<String, dynamic>);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
