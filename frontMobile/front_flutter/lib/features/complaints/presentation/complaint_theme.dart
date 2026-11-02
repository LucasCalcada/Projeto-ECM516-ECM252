import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Compatibility entry for the explicit preview; production uses HiveTheme globally.
abstract final class ComplaintTheme {
  static ThemeData apply(ThemeData base) => HiveTheme.apply(base);
}
