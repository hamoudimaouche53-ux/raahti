// Traces to: docs/design/foundations.md §2.2, ADR-0018 font-bundling
// follow-up (assets/fonts/README.md).
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/core/theme/font_tokens.dart";

void main() {
  group("RahatiTheme.resolveForLocale", () {
    test("Latin locales (fr, en) keep the Roboto family untouched", () {
      final ThemeData fr = RahatiTheme.resolveForLocale(
        RahatiTheme.light,
        const Locale("fr"),
      );
      final ThemeData en = RahatiTheme.resolveForLocale(
        RahatiTheme.light,
        const Locale("en"),
      );
      expect(fr.textTheme.bodyLarge?.fontFamily, RahatiFonts.latin);
      expect(en.textTheme.bodyLarge?.fontFamily, RahatiFonts.latin);
      expect(identical(fr, RahatiTheme.light), isTrue);
    });

    test(
      "Arabic locale swaps display/headline/titleLarge to Noto Kufi Arabic",
      () {
        final ThemeData ar = RahatiTheme.resolveForLocale(
          RahatiTheme.light,
          const Locale("ar"),
        );
        expect(
          ar.textTheme.displayLarge?.fontFamily,
          RahatiFonts.arabicDisplay,
        );
        expect(
          ar.textTheme.headlineSmall?.fontFamily,
          RahatiFonts.arabicDisplay,
        );
        expect(ar.textTheme.titleLarge?.fontFamily, RahatiFonts.arabicDisplay);
      },
    );

    test("Arabic locale swaps titleMedium/Small, body, and label to "
        "Noto Naskh Arabic", () {
      final ThemeData ar = RahatiTheme.resolveForLocale(
        RahatiTheme.light,
        const Locale("ar"),
      );
      expect(ar.textTheme.titleMedium?.fontFamily, RahatiFonts.arabicBody);
      expect(ar.textTheme.bodyMedium?.fontFamily, RahatiFonts.arabicBody);
      expect(ar.textTheme.labelLarge?.fontFamily, RahatiFonts.arabicBody);
    });

    test("works identically for the dark theme", () {
      final ThemeData ar = RahatiTheme.resolveForLocale(
        RahatiTheme.dark,
        const Locale("ar"),
      );
      expect(ar.textTheme.displayLarge?.fontFamily, RahatiFonts.arabicDisplay);
      expect(ar.colorScheme.brightness, Brightness.dark);
    });
  });
}
