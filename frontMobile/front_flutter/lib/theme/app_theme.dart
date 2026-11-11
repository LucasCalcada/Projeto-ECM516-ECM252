import 'package:flutter/material.dart';

/// Shared semantic tokens from audit/design-system.md (DS-01 through DS-08).
abstract final class HiveColors {
  static const canvas = Color(0xFF0A0A0A);
  static const surface = Color(0xFF171717);
  static const raised = Color(0xFF262626);
  static const divider = Color(0xFF262626);
  static const boundary = Color(0xFF737373);
  static const text = Color(0xFFF5F5F5);
  static const body = Color(0xFFD4D4D4);
  static const secondary = Color(0xFFA1A1A1);
  static const primary = Color(0xFF53EAFD);
  static const success = Color(0xFF05DF72);
  static const warning = Color(0xFFFDC700);
  static const danger = Color(0xFFFF6467);
}

abstract final class HiveTheme {
  static ThemeData apply(ThemeData base) {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
    );
    const panelShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    );
    const fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide(color: HiveColors.boundary),
    );
    TextStyle type(
      double size,
      double line,
      FontWeight weight, {
      Color color = HiveColors.text,
    }) => TextStyle(
      fontSize: size,
      height: line / size,
      fontWeight: weight,
      color: color,
    );
    final buttonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      shape: const WidgetStatePropertyAll(shape),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(type(14, 20, FontWeight.w600)),
      side: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? const BorderSide(color: HiveColors.primary, width: 2)
            : BorderSide.none,
      ),
    );
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: HiveColors.canvas,
      canvasColor: HiveColors.canvas,
      colorScheme: const ColorScheme.dark(
        primary: HiveColors.primary,
        onPrimary: HiveColors.canvas,
        secondary: HiveColors.primary,
        onSecondary: HiveColors.canvas,
        surface: HiveColors.surface,
        onSurface: HiveColors.text,
        onSurfaceVariant: HiveColors.secondary,
        error: HiveColors.danger,
      ),
      textTheme: TextTheme(
        headlineSmall: type(24, 32, FontWeight.w700),
        headlineMedium: type(24, 32, FontWeight.w700),
        titleLarge: type(20, 28, FontWeight.w600),
        titleMedium: type(16, 24, FontWeight.w600),
        titleSmall: type(16, 24, FontWeight.w600),
        bodyLarge: type(16, 24, FontWeight.w400, color: HiveColors.body),
        bodyMedium: type(16, 24, FontWeight.w400, color: HiveColors.body),
        bodySmall: type(12, 16, FontWeight.w400, color: HiveColors.secondary),
        labelLarge: type(14, 20, FontWeight.w600),
        labelMedium: type(14, 20, FontWeight.w500),
        labelSmall: type(12, 16, FontWeight.w500),
      ),
      cardTheme: const CardThemeData(
        color: HiveColors.surface,
        elevation: 0,
        shape: panelShape,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: HiveColors.surface,
        foregroundColor: HiveColors.text,
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: HiveColors.surface),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: HiveColors.canvas,
        contentPadding: EdgeInsets.all(12),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide: BorderSide(color: HiveColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide: BorderSide(color: HiveColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide: BorderSide(color: HiveColors.danger, width: 2),
        ),
        errorMaxLines: 4,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: buttonStyle.copyWith(
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? const BorderSide(color: HiveColors.canvas, width: 2)
                : BorderSide.none,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? HiveColors.raised
                : HiveColors.primary,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? HiveColors.secondary
                : HiveColors.canvas,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: buttonStyle.copyWith(
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? const BorderSide(color: HiveColors.canvas, width: 2)
                : BorderSide.none,
          ),
          backgroundColor: const WidgetStatePropertyAll(HiveColors.primary),
          foregroundColor: const WidgetStatePropertyAll(HiveColors.canvas),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: buttonStyle.copyWith(
          foregroundColor: const WidgetStatePropertyAll(HiveColors.text),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(style: buttonStyle),
      chipTheme: base.chipTheme.copyWith(
        shape: shape,
        side: BorderSide.none,
        backgroundColor: HiveColors.raised,
        selectedColor: HiveColors.primary,
        labelStyle: type(14, 20, FontWeight.w500),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: HiveColors.raised,
        elevation: 0,
        shape: panelShape,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: HiveColors.primary,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: HiveColors.primary,
        selectionColor: Color(0x6653EAFD),
      ),
    );
  }
}
