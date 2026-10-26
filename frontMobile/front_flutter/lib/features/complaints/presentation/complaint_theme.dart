import 'package:flutter/material.dart';

/// Semantic colors from docs/frontend/tokens.json for this feature.
class ComplaintPalette {
  const ComplaintPalette._({
    required this.canvas,
    required this.base,
    required this.raised,
    required this.input,
    required this.primary,
    required this.onPrimary,
    required this.text,
    required this.secondary,
    required this.muted,
    required this.accent,
    required this.selection,
    required this.focus,
    required this.success,
    required this.successBackground,
    required this.warning,
    required this.warningBackground,
    required this.error,
    required this.errorBackground,
    required this.info,
    required this.infoBackground,
  });

  factory ComplaintPalette.of(BuildContext context) =>
      _forBrightness(Theme.of(context).brightness);

  final Color canvas;
  final Color base;
  final Color raised;
  final Color input;
  final Color primary;
  final Color onPrimary;
  final Color text;
  final Color secondary;
  final Color muted;
  final Color accent;
  final Color selection;
  final Color focus;
  final Color success;
  final Color successBackground;
  final Color warning;
  final Color warningBackground;
  final Color error;
  final Color errorBackground;
  final Color info;
  final Color infoBackground;

  static ComplaintPalette _forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  static const _light = ComplaintPalette._(
    canvas: Color(0xFFFAFAFA),
    base: Color(0xFFFFFFFF),
    raised: Color(0xFFF5F5F5),
    input: Color(0xFFFFFFFF),
    primary: Color(0xFF2563EB),
    onPrimary: Color(0xFFFFFFFF),
    text: Color(0xFF171717),
    secondary: Color(0xFF404040),
    muted: Color(0xFF525252),
    accent: Color(0xFF0E7490),
    selection: Color(0xFFEFF6FF),
    focus: Color(0xFF2563EB),
    success: Color(0xFF166534),
    successBackground: Color(0xFFF0FDF4),
    warning: Color(0xFF92400E),
    warningBackground: Color(0xFFFFFBEB),
    error: Color(0xFF991B1B),
    errorBackground: Color(0xFFFEF2F2),
    info: Color(0xFF1E40AF),
    infoBackground: Color(0xFFEFF6FF),
  );

  static const _dark = ComplaintPalette._(
    canvas: Color(0xFF0A0A0A),
    base: Color(0xFF171717),
    raised: Color(0xFF262626),
    input: Color(0xFF0A0A0A),
    primary: Color(0xFF2563EB),
    onPrimary: Color(0xFFFFFFFF),
    text: Color(0xFFF5F5F5),
    secondary: Color(0xFFD4D4D4),
    muted: Color(0xFFA3A3A3),
    accent: Color(0xFF67E8F9),
    selection: Color(0xFF172554),
    focus: Color(0xFF60A5FA),
    success: Color(0xFF86EFAC),
    successBackground: Color(0xFF052E16),
    warning: Color(0xFFFCD34D),
    warningBackground: Color(0xFF451A03),
    error: Color(0xFFFCA5A5),
    errorBackground: Color(0xFF450A0A),
    info: Color(0xFFBFDBFE),
    infoBackground: Color(0xFF172554),
  );
}

/// Applied only around the complaints route, preserving the existing app theme.
abstract final class ComplaintTheme {
  static ThemeData apply(ThemeData base) {
    final colors = ComplaintPalette._forBrightness(base.brightness);
    const controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    );
    final textTheme = base.textTheme.apply(
      bodyColor: colors.text,
      displayColor: colors.text,
    );
    TextStyle textStyle(
      TextStyle? original,
      double size,
      double lineHeight,
      FontWeight weight,
    ) => (original ?? const TextStyle()).copyWith(
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      letterSpacing: 0,
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.canvas,
      canvasColor: colors.canvas,
      cardColor: colors.base,
      focusColor: colors.selection,
      disabledColor: colors.muted,
      colorScheme: base.colorScheme.copyWith(
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        secondary: colors.accent,
        onSecondary: colors.canvas,
        surface: colors.base,
        onSurface: colors.text,
        onSurfaceVariant: colors.secondary,
        surfaceContainerLowest: colors.canvas,
        surfaceContainerLow: colors.base,
        surfaceContainer: colors.raised,
        surfaceContainerHigh: colors.raised,
        surfaceContainerHighest: colors.raised,
        error: colors.error,
        onError: colors.errorBackground,
      ),
      textTheme: textTheme.copyWith(
        displaySmall: textStyle(
          textTheme.displaySmall,
          30,
          36,
          FontWeight.w700,
        ),
        headlineLarge: textStyle(
          textTheme.headlineLarge,
          30,
          36,
          FontWeight.w700,
        ),
        headlineMedium: textStyle(
          textTheme.headlineMedium,
          24,
          32,
          FontWeight.w700,
        ),
        headlineSmall: textStyle(
          textTheme.headlineSmall,
          24,
          32,
          FontWeight.w700,
        ),
        titleLarge: textStyle(textTheme.titleLarge, 20, 28, FontWeight.w600),
        titleMedium: textStyle(textTheme.titleMedium, 18, 24, FontWeight.w600),
        titleSmall: textStyle(textTheme.titleSmall, 18, 24, FontWeight.w600),
        bodyLarge: textStyle(textTheme.bodyLarge, 16, 24, FontWeight.w400),
        bodyMedium: textStyle(textTheme.bodyMedium, 14, 20, FontWeight.w400),
        bodySmall: textStyle(textTheme.bodySmall, 12, 16, FontWeight.w400),
        labelLarge: textStyle(textTheme.labelLarge, 14, 20, FontWeight.w600),
        labelMedium: textStyle(textTheme.labelMedium, 14, 20, FontWeight.w600),
        labelSmall: textStyle(textTheme.labelSmall, 12, 16, FontWeight.w400),
      ),
      cardTheme: CardThemeData(
        color: colors.base,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide.none,
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: colors.raised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: const OutlineInputBorder(borderSide: BorderSide.none),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide.none,
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide.none,
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide.none,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.focus, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        hintStyle: textStyle(
          textTheme.bodyLarge,
          16,
          24,
          FontWeight.w400,
        ).copyWith(color: colors.muted),
        labelStyle: textStyle(
          textTheme.labelLarge,
          14,
          20,
          FontWeight.w600,
        ).copyWith(color: colors.secondary),
        errorStyle: textStyle(
          textTheme.bodyMedium,
          14,
          20,
          FontWeight.w400,
        ).copyWith(color: colors.error),
        errorMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              disabledBackgroundColor: colors.raised,
              disabledForegroundColor: colors.muted,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: controlShape,
              textStyle: textStyle(
                textTheme.labelLarge,
                14,
                20,
                FontWeight.w600,
              ),
            ).copyWith(
              side: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.focused)
                    ? BorderSide(color: colors.focus, width: 2)
                    : BorderSide.none;
              }),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              foregroundColor: base.brightness == Brightness.dark
                  ? colors.focus
                  : colors.primary,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: controlShape,
              textStyle: textStyle(
                textTheme.labelLarge,
                14,
                20,
                FontWeight.w600,
              ),
            ).copyWith(
              side: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.focused)
                    ? BorderSide(color: colors.focus, width: 2)
                    : BorderSide.none;
              }),
            ),
      ),
      iconTheme: base.iconTheme.copyWith(color: colors.secondary, size: 20),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: colors.raised,
        selectedColor: colors.selection,
        labelStyle: textStyle(
          textTheme.labelLarge,
          14,
          20,
          FontWeight.w600,
        ).copyWith(color: colors.text),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.secondary,
          minimumSize: const Size(48, 48),
          shape: controlShape,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.base,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide.none,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.primary,
        selectionColor: colors.selection,
        selectionHandleColor: colors.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.primary),
    );
  }
}
