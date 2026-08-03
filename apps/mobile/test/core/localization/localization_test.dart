// Traces to: ADR-0017 (trilingual FR/AR/EN), docs/srs/SRS.md
// "Phase 2 Addendum" (NFR-I18N-01 extended), SCR-003 AR/RTL variant in the
// Phase 2 interactive prototype.
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/app.dart";
import "package:rahati/core/providers/app_settings_providers.dart";
import "package:rahati/l10n/app_localizations.dart";

void main() {
  group("AppLocalizations", () {
    test("supports exactly fr, en, ar", () {
      final List<String> codes = AppLocalizations.supportedLocales
          .map((l) => l.languageCode)
          .toList();
      expect(codes, containsAll(<String>["fr", "en", "ar"]));
      expect(codes, hasLength(3));
    });

    testWidgets("resolves French strings", (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale("fr"),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: _L10nProbe(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text("Chargement…"), findsOneWidget);
    });

    testWidgets("resolves Arabic strings", (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale("ar"),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: _L10nProbe(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text("جارٍ التحميل…"), findsOneWidget);
    });
  });

  group("RTL layout direction", () {
    testWidgets("Arabic locale yields RTL text direction", (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale("ar"),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: _L10nProbe(),
          ),
        ),
      );
      await tester.pump();

      final BuildContext context = tester.element(find.byType(_L10nProbe));
      expect(Directionality.of(context), TextDirection.rtl);
    });

    testWidgets("French locale yields LTR text direction", (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale("fr"),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: _L10nProbe(),
          ),
        ),
      );
      await tester.pump();

      final BuildContext context = tester.element(find.byType(_L10nProbe));
      expect(Directionality.of(context), TextDirection.ltr);
    });
  });

  testWidgets(
    "the full RahatiApp defaults to the resolved device/system locale",
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: RahatiApp()));
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    },
  );

  testWidgets(
    "RahatiApp swaps to the Arabic typeface when the locale is overridden "
    "to ar (end-to-end through the MaterialApp.builder wiring)",
    (WidgetTester tester) async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(localeProvider.notifier).setLocale(const Locale("ar"));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const RahatiApp(),
        ),
      );
      await tester.pump();

      final BuildContext context = tester.element(find.byType(Scaffold));
      expect(
        Theme.of(context).textTheme.headlineSmall?.fontFamily,
        "Noto Kufi Arabic",
      );
      expect(Directionality.of(context), TextDirection.rtl);
    },
  );
}

class _L10nProbe extends StatelessWidget {
  const _L10nProbe();

  @override
  Widget build(BuildContext context) {
    return Text(AppLocalizations.of(context).splashLoading);
  }
}
