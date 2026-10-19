import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/lang/login_localizations.dart';
import 'package:front_flutter/types/auth_result.dart';

Set<String> keys(Map<String, dynamic> data, [String prefix = '']) => {
  for (final entry in data.entries)
    if (entry.value is Map<String, dynamic>)
      ...keys(entry.value as Map<String, dynamic>, '$prefix${entry.key}.')
    else
      '$prefix${entry.key}',
};

void main() {
  test(
    'all languages contain the same messages, including every auth failure',
    () {
      Set<String>? reference;
      for (final language in ['pt', 'en', 'es']) {
        final data = jsonDecode(
          File('lib/lang/$language/login.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        reference ??= keys(data);
        expect(keys(data), reference, reason: language);
        final strings = LoginLocalizations(data);
        for (final key in reference) {
          expect(strings.text(key), isNotEmpty, reason: '$language:$key');
        }
        for (final error in AuthFailure.values) {
          expect(strings.error(error), isNotEmpty, reason: '$language:$error');
        }
      }
    },
  );
}
