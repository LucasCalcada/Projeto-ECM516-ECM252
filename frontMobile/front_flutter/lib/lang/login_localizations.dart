import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../types/auth_result.dart';

class LoginLocalizations {
  const LoginLocalizations(this._messages);

  final Map<String, dynamic> _messages;
  static const supportedLocales = [Locale('pt'), Locale('en'), Locale('es')];
  static const delegate = _LoginLocalizationsDelegate();

  static LoginLocalizations of(BuildContext context) =>
      Localizations.of<LoginLocalizations>(context, LoginLocalizations)!;

  String text(String key) {
    dynamic value = _messages;
    for (final part in key.split('.')) {
      value = (value as Map<String, dynamic>)[part];
    }
    return value as String;
  }

  String error(AuthFailure failure) => text('errors.${failure.name}');
}

class _LoginLocalizationsDelegate
    extends LocalizationsDelegate<LoginLocalizations> {
  const _LoginLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => LoginLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<LoginLocalizations> load(Locale locale) async {
    final source = await rootBundle.loadString(
      'lib/lang/${locale.languageCode}/login.json',
    );
    return LoginLocalizations(jsonDecode(source) as Map<String, dynamic>);
  }

  @override
  bool shouldReload(_LoginLocalizationsDelegate old) => false;
}
