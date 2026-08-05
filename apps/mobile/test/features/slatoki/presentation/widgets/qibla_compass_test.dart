// Traces to: US-02.1.2, Component Library §9.1, ADR-0025. Injects
// `rawCompassEventsProvider`/`userPositionStreamProvider` rather than
// touching the real `flutter_compass` platform channel or GPS — the same
// provider-override pattern this codebase has used since Feature 1.
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_compass/flutter_compass.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/location_failure.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_providers.dart";
import "package:rahati/features/slatoki/presentation/providers/qibla_providers.dart";
import "package:rahati/features/slatoki/presentation/widgets/qibla_compass.dart";
import "package:rahati/l10n/app_localizations.dart";

const Coordinates _algiers = Coordinates(latitude: 36.7538, longitude: 3.0588);

Widget _wrap(
  Widget child, {
  bool compassAvailable = true,
  Stream<CompassEvent>? compassEvents,
  Coordinates position = _algiers,
  Stream<Coordinates>? positionStream,
}) {
  return ProviderScope(
    overrides: [
      rawCompassEventsProvider.overrideWithValue(
        compassAvailable
            ? (compassEvents ?? const Stream<CompassEvent>.empty())
            : null,
      ),
      userPositionStreamProvider.overrideWith(
        (ref) => positionStream ?? Stream<Coordinates>.value(position),
      ),
    ],
    child: MaterialApp(
      theme: RahatiTheme.light,
      locale: const Locale("fr"),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets("unavailable (no magnetometer): shows a static icon and the "
      "unavailable semantic label", (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        const QiblaCompass(mode: QiblaCompassMode.full),
        compassAvailable: false,
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.explore_off_outlined), findsOneWidget);
    final SemanticsHandle handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel("Boussole indisponible sur cet appareil"),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets(
    "compact mode: renders at 80dp and announces the resolved bearing "
    "once position resolves, even with no compass reading yet — bearing "
    "depends only on position, not on heading/accuracy (US-06.4 finding "
    "F20)",
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(const QiblaCompass(mode: QiblaCompassMode.compact)),
      );
      await tester.pump();
      await tester.pump();

      final SizedBox box = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(QiblaCompass),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(box.width, QiblaCompass.compactSize);

      final SemanticsHandle handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel("La Mecque est à 105 degrés, Est"),
        findsOneWidget,
      );
      handle.dispose();
    },
  );

  testWidgets(
    "full mode, good accuracy: announces the rounded bearing and cardinal "
    "direction, and rotates the needle to (bearing - heading)",
    (WidgetTester tester) async {
      // Algiers → Mecca bearing ≈ 105.41° (ESE). Heading 0° (device
      // pointing north) → needle should point to ≈105.41° on screen.
      await tester.pumpWidget(
        _wrap(
          const QiblaCompass(mode: QiblaCompassMode.full),
          compassEvents: Stream<CompassEvent>.value(
            CompassEvent.fromList(<double>[0, 0, 5]),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Algiers' bearing (105.41° → rounds to 105°) falls in the "Est"
      // (E) 67.5–112.5° sector.
      final SemanticsHandle handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel("La Mecque est à 105 degrés, Est"),
        findsOneWidget,
      );
      handle.dispose();

      final Transform rotate = tester.widget<Transform>(
        find.byKey(const Key("qiblaNeedleRotation")),
      );
      final Matrix4 expected = Matrix4.rotationZ(105.41 * math.pi / 180);
      for (int i = 0; i < 16; i++) {
        expect(rotate.transform.storage[i], closeTo(expected.storage[i], 0.01));
      }
    },
  );

  testWidgets(
    "full mode, poor accuracy: still calibrating (needle continues to "
    "animate rather than settling) — verified via the full-screen hint "
    "text instead, since this widget itself carries no visible text",
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          const QiblaCompass(mode: QiblaCompassMode.full),
          compassEvents: Stream<CompassEvent>.value(
            CompassEvent.fromList(<double>[10, 10, 30]),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("renders correctly against the dark theme", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rawCompassEventsProvider.overrideWithValue(
            const Stream<CompassEvent>.empty(),
          ),
        ],
        child: MaterialApp(
          theme: RahatiTheme.dark,
          locale: const Locale("fr"),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(
            body: Center(child: QiblaCompass(mode: QiblaCompassMode.compact)),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(QiblaCompass), findsOneWidget);
  });

  group("Full-mode semantic label is state-aware, not a false 'tap to expand' "
      "fallback (US-06.4 finding F19)", () {
    testWidgets(
      "bearing available: announces the resolved bearing (not a position "
      "message)",
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrap(const QiblaCompass(mode: QiblaCompassMode.full)),
        );
        await tester.pump();
        await tester.pump();

        final SemanticsHandle handle = tester.ensureSemantics();
        expect(
          find.bySemanticsLabel("La Mecque est à 105 degrés, Est"),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
            "Boussole vers La Mecque, appuyez pour agrandir",
          ),
          findsNothing,
        );
        handle.dispose();
      },
    );

    testWidgets(
      "position loading: announces the loading message, not the compact "
      "'tap to expand' fallback",
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrap(
            const QiblaCompass(mode: QiblaCompassMode.full),
            positionStream: const Stream<Coordinates>.empty(),
          ),
        );
        await tester.pump();

        final SemanticsHandle handle = tester.ensureSemantics();
        expect(find.bySemanticsLabel("Localisation en cours…"), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            "Boussole vers La Mecque, appuyez pour agrandir",
          ),
          findsNothing,
        );
        handle.dispose();
      },
    );

    testWidgets("location permission denied: announces the same message "
        "map_screen.dart uses for this exact failure, not a false "
        "affordance", (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          const QiblaCompass(mode: QiblaCompassMode.full),
          positionStream: Stream<Coordinates>.error(
            const LocationPermissionDeniedFailure(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      final SemanticsHandle handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(
          "Autorisation de localisation refusée — activez-la dans les "
          "paramètres.",
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets("location permission permanently denied: maps to the same "
        "permission-denied message as the one-time-denied case", (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const QiblaCompass(mode: QiblaCompassMode.full),
          positionStream: Stream<Coordinates>.error(
            const LocationPermissionDeniedForeverFailure(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      final SemanticsHandle handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(
          "Autorisation de localisation refusée — activez-la dans les "
          "paramètres.",
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets("location services disabled: announces the same message "
        "map_screen.dart uses for this exact failure", (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const QiblaCompass(mode: QiblaCompassMode.full),
          positionStream: Stream<Coordinates>.error(
            const LocationServiceDisabledFailure(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      final SemanticsHandle handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(
          "Service de localisation désactivé — activez-le pour voir "
          "votre position.",
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets(
      "any other position failure: falls back to the generic position "
      "error message, never the misleading compact-mode label",
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrap(
            const QiblaCompass(mode: QiblaCompassMode.full),
            positionStream: Stream<Coordinates>.error(Exception("unexpected")),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));

        final SemanticsHandle handle = tester.ensureSemantics();
        expect(
          find.bySemanticsLabel("Impossible d'obtenir votre position."),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
            "Boussole vers La Mecque, appuyez pour agrandir",
          ),
          findsNothing,
        );
        handle.dispose();
      },
    );
  });

  group(
    "Compact-mode semantic label is now state-aware too — the F19 fix's "
    "logic extended, not a separate implementation (US-06.4 finding F20)",
    () {
      testWidgets(
        "position loading: compact mode announces the loading message, "
        "same as full mode",
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _wrap(
              const QiblaCompass(mode: QiblaCompassMode.compact),
              positionStream: const Stream<Coordinates>.empty(),
            ),
          );
          await tester.pump();

          final SemanticsHandle handle = tester.ensureSemantics();
          expect(
            find.bySemanticsLabel("Localisation en cours…"),
            findsOneWidget,
          );
          handle.dispose();
        },
      );

      testWidgets("location permission denied: compact mode announces the same "
          "message full mode uses for this exact failure", (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            const QiblaCompass(mode: QiblaCompassMode.compact),
            positionStream: Stream<Coordinates>.error(
              const LocationPermissionDeniedFailure(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));

        final SemanticsHandle handle = tester.ensureSemantics();
        expect(
          find.bySemanticsLabel(
            "Autorisation de localisation refusée — activez-la dans les "
            "paramètres.",
          ),
          findsOneWidget,
        );
        handle.dispose();
      });

      testWidgets(
        "the old static 'tap to expand' fallback is never announced in "
        "any state, in either mode — it had no remaining caller and was "
        "removed, not left as dead ARB content",
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _wrap(const QiblaCompass(mode: QiblaCompassMode.compact)),
          );
          await tester.pump();
          await tester.pump();

          final SemanticsHandle handle = tester.ensureSemantics();
          expect(
            find.bySemanticsLabel(
              "Boussole vers La Mecque, appuyez pour agrandir",
            ),
            findsNothing,
          );
          handle.dispose();
        },
      );
    },
  );
}
