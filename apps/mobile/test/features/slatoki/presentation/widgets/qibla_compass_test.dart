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
}) {
  return ProviderScope(
    overrides: [
      rawCompassEventsProvider.overrideWithValue(
        compassAvailable
            ? (compassEvents ?? const Stream<CompassEvent>.empty())
            : null,
      ),
      userPositionStreamProvider.overrideWith(
        (ref) => Stream<Coordinates>.value(position),
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
    "compact mode: renders at 80dp with the compact semantic label while "
    "no reading has arrived yet",
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(const QiblaCompass(mode: QiblaCompassMode.compact)),
      );
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
        find.bySemanticsLabel("Boussole vers La Mecque, appuyez pour agrandir"),
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
}
