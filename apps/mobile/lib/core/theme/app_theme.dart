import "package:flutter/cupertino.dart" show CupertinoPageTransitionsBuilder;
import "package:flutter/material.dart";

import "color_tokens.dart";
import "font_tokens.dart";
import "motion_tokens.dart";

/// Assembles the light and dark [ThemeData] from the RAHATI design tokens.
///
/// Traces to: docs/design/foundations.md, ADR-0011 (Material Design 3 as
/// the official design system), ADR-0018 (Flutter project foundation).
///
/// Per-component theme overrides (NavigationBarThemeData, ChipThemeData,
/// CardThemeData, etc. — docs/design/component-library.md) are added
/// incrementally as each component is first used by a screen, not
/// pre-declared here unused.
abstract final class RahatiTheme {
  static ThemeData light = _build(
    colorScheme: RahatiColorTokens.light,
    functionalColors: RahatiFunctionalColors.light,
  );

  static ThemeData dark = _build(
    colorScheme: RahatiColorTokens.dark,
    functionalColors: RahatiFunctionalColors.dark,
  );

  static ThemeData _build({
    required ColorScheme colorScheme,
    required RahatiFunctionalColors functionalColors,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[functionalColors],
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: RahatiFonts.latin,
      // Reduced-motion route transitions (US-06.4 / foundations.md §5.3) —
      // see RahatiReducedMotionPageTransitionsBuilder's own doc comment.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: RahatiReducedMotionPageTransitionsBuilder(
            ZoomPageTransitionsBuilder(),
          ),
          TargetPlatform.iOS: RahatiReducedMotionPageTransitionsBuilder(
            CupertinoPageTransitionsBuilder(),
          ),
          TargetPlatform.macOS: RahatiReducedMotionPageTransitionsBuilder(
            CupertinoPageTransitionsBuilder(),
          ),
          TargetPlatform.linux: RahatiReducedMotionPageTransitionsBuilder(
            ZoomPageTransitionsBuilder(),
          ),
          TargetPlatform.windows: RahatiReducedMotionPageTransitionsBuilder(
            ZoomPageTransitionsBuilder(),
          ),
          TargetPlatform.fuchsia: RahatiReducedMotionPageTransitionsBuilder(
            ZoomPageTransitionsBuilder(),
          ),
        },
      ),
    );
  }

  /// Returns [base] with its text styles swapped to the Arabic typeface
  /// pairing when [locale] is Arabic, per docs/design/foundations.md §2.2:
  /// **Noto Kufi Arabic** for display/headline/titleLarge (geometric,
  /// pairs with Roboto's structure at prominent sizes) and **Noto Naskh
  /// Arabic** for titleMedium/titleSmall/body/label (optimized legibility
  /// at small sizes). French/English keep the Latin [RahatiFonts.latin]
  /// family set in [_build] — Arabic is the only locale that changes the
  /// type family (RTL layout mirroring is otherwise identical to Foundations
  /// §2.3's "trilingual rule": the scale itself never changes, only the
  /// family and 1sp).
  ///
  /// Called from `MaterialApp.builder` in lib/app.dart with the *resolved*
  /// locale (explicit user override or system default) — this function does
  /// not itself guess the active locale.
  static ThemeData resolveForLocale(ThemeData base, Locale locale) {
    if (locale.languageCode != "ar") return base;
    return base.copyWith(
      textTheme: _arabicTextTheme(base.textTheme),
      primaryTextTheme: _arabicTextTheme(base.primaryTextTheme),
    );
  }

  static TextTheme _arabicTextTheme(TextTheme t) {
    TextStyle? display(TextStyle? s) =>
        s?.copyWith(fontFamily: RahatiFonts.arabicDisplay);
    TextStyle? body(TextStyle? s) =>
        s?.copyWith(fontFamily: RahatiFonts.arabicBody);

    return t.copyWith(
      displayLarge: display(t.displayLarge),
      displayMedium: display(t.displayMedium),
      displaySmall: display(t.displaySmall),
      headlineLarge: display(t.headlineLarge),
      headlineMedium: display(t.headlineMedium),
      headlineSmall: display(t.headlineSmall),
      titleLarge: display(t.titleLarge),
      titleMedium: body(t.titleMedium),
      titleSmall: body(t.titleSmall),
      bodyLarge: body(t.bodyLarge),
      bodyMedium: body(t.bodyMedium),
      bodySmall: body(t.bodySmall),
      labelLarge: body(t.labelLarge),
      labelMedium: body(t.labelMedium),
      labelSmall: body(t.labelSmall),
    );
  }
}
