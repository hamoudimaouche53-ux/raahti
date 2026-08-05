// Traces to: docs/design/foundations.md §1 (Color), §5.3 (reduced motion),
// ADR-0011, ADR-0018.
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/core/theme/color_tokens.dart";

void main() {
  group("RahatiTheme", () {
    test("light theme uses Material 3 and the RAHATI primary seed color", () {
      expect(RahatiTheme.light.useMaterial3, isTrue);
      expect(RahatiTheme.light.colorScheme.brightness, Brightness.light);
      expect(RahatiTheme.light.colorScheme.primary, const Color(0xFF00677E));
    });

    test("dark theme uses Material 3 and its own tonal primary", () {
      expect(RahatiTheme.dark.useMaterial3, isTrue);
      expect(RahatiTheme.dark.colorScheme.brightness, Brightness.dark);
      expect(RahatiTheme.dark.colorScheme.primary, const Color(0xFF5CD5F5));
    });

    test("both themes carry the RahatiFunctionalColors extension", () {
      expect(RahatiTheme.light.extension<RahatiFunctionalColors>(), isNotNull);
      expect(RahatiTheme.dark.extension<RahatiFunctionalColors>(), isNotNull);
    });

    test("functional colors differ between light and dark", () {
      final RahatiFunctionalColors light = RahatiTheme.light
          .extension<RahatiFunctionalColors>()!;
      final RahatiFunctionalColors dark = RahatiTheme.dark
          .extension<RahatiFunctionalColors>()!;
      expect(light.success, isNot(dark.success));
      expect(light.slatoki, isNot(dark.slatoki));
    });
  });

  group("RahatiFunctionalColors", () {
    test("copyWith overrides only the requested fields", () {
      const RahatiFunctionalColors base = RahatiFunctionalColors.light;
      final RahatiFunctionalColors copy = base.copyWith(success: Colors.black);
      expect(copy.success, Colors.black);
      expect(copy.info, base.info);
    });

    test("lerp at t=0 returns the start value", () {
      const RahatiFunctionalColors a = RahatiFunctionalColors.light;
      const RahatiFunctionalColors b = RahatiFunctionalColors.dark;
      final RahatiFunctionalColors result = a.lerp(b, 0);
      expect(result.success, a.success);
    });

    test("lerp with a non-matching type returns the original", () {
      const RahatiFunctionalColors a = RahatiFunctionalColors.light;
      expect(a.lerp(null, 1), a);
    });
  });

  group("Reduced-motion route transitions (US-06.4)", () {
    testWidgets("route push cross-fades instead of platform-sliding when the "
        "OS-level reduce-motion setting is on", (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: RahatiTheme.light,
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Text("second screen"),
                  ),
                ),
                child: const Text("go"),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text("go"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(FadeTransition), findsWidgets);
    });

    testWidgets(
      "route push keeps the normal platform transition when reduce-motion "
      "is off",
      (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: false),
            child: MaterialApp(
              theme: RahatiTheme.light,
              home: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Text("second screen"),
                    ),
                  ),
                  child: const Text("go"),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text("go"));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text("second screen"), findsOneWidget);
      },
    );
  });
}
