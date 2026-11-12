import '../types/complaint_failure.dart';

import 'package:flutter/material.dart';

import '../lang/app_localizations.dart';
import '../lang/complaint_messages.dart';

class ComplaintStrings {
  const ComplaintStrings._(this.languageCode, this.messages);
  factory ComplaintStrings.forLanguage(String code) {
    final language = code.toLowerCase().split(RegExp('[-_]')).first;
    final effective = complaintMessages.containsKey(language) ? language : 'pt';
    return ComplaintStrings._(effective, complaintMessages[effective]!);
  }
  factory ComplaintStrings.of(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final global = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    if (global == null) return ComplaintStrings.forLanguage(locale);
    return ComplaintStrings._(locale, {
      for (final entry in global.messages.entries)
        if (entry.key.startsWith('complaints.') && entry.value is String)
          entry.key.substring(11): entry.value as String,
    });
  }
  final String languageCode;
  final Map<String, String> messages;
  String text(String key) =>
      messages[key] ?? complaintMessages['pt']?[key] ?? key;
  String date(DateTime value, {BuildContext? context}) {
    final local = value.toLocal();
    if (context != null) {
      return MaterialLocalizations.of(context).formatMediumDate(local);
    }
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return languageCode == 'en'
        ? '$month/$day/${local.year}'
        : '$day/$month/${local.year}';
  }

  String failure(ComplaintFailure? value) => text(switch (value) {
    ComplaintFailure.validation => 'failureValidation',
    ComplaintFailure.forbidden => 'failureForbidden',
    ComplaintFailure.notFound => 'failureNotFound',
    ComplaintFailure.conflict => 'failureConflict',
    ComplaintFailure.network => 'failureNetwork',
    ComplaintFailure.invalidResponse => 'failureInvalidResponse',
    _ => 'mutationError',
  });
}
