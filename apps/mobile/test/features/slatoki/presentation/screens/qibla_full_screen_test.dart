// Traces to: SCR-009, docs/design/wireframes/mobile-slatoki.md#scr-009-qibla-full-screen-flagship.
import "package:flutter/material.dart";
import "package:flutter_compass/flutter_compass.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_providers.dart";
import "package:rahati/features/slatoki/presentation/providers/qibla_providers.dart";
import "package:rahati/features/slatoki/presentation/screens/qibla_full_screen.dart";
import "package:rahati/features/slatoki/presentation/widgets/qibla_compass.dart";
import "package:rahati/l10n/app_localizations.dart";

const Coordinates _algiers = Coordinates(latitude: 36.7538, longitude: 3.0588);

Widget _wrap({
  bool compassAvailable = true,
  Stream<CompassEvent>? compassEvents,
  ThemeData? theme,
  Locale locale = const Locale("fr"),
}) {
  return ProviderScope(
    overrides: [
      rawCompassEventsProvider.overrideWithValue(
        compassAvailable
            ? (compassEvents ?? const Stream<CompassEvent>.empty())
            : null,
      ),
      userPositionStreamProvider.overrideWith(
        (ref) => Stream<Coordinates>.value(_algiers),
      ),
    ],
    child: MaterialApp(
      theme: theme ?? RahatiTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const QiblaFullScreen(),
    ),
  );
}

void main() {
  testWidgets("shows the full-mode compass", (WidgetTester tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();

    expect(find.byType(QiblaCompass), findsOneWidget);
    final QiblaCompass compass = tester.widget<QiblaCompass>(
      find.byType(QiblaCompass),
    );
    expect(compass.mode, QiblaCompassMode.full);
  });

  testWidgets("good accuracy: shows the degree readout, no calibration hint", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        compassEvents: Stream<CompassEvent>.value(
          CompassEvent.fromList(<double>[0, 0, 5]),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining("° — La Mecque"), findsOneWidget);
    expect(
      find.text("Déplacez votre téléphone en 8 pour calibrer"),
      findsNothing,
    );
  });

  testWidgets("poor accuracy: shows the calibration hint", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        compassEvents: Stream<CompassEvent>.value(
          CompassEvent.fromList(<double>[0, 0, 30]),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text("Déplacez votre téléphone en 8 pour calibrer"),
      findsOneWidget,
    );
  });

  testWidgets("magnetometer unavailable: shows the errorContainer banner", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(compassAvailable: false));
    await tester.pump();

    expect(find.text("Boussole indisponible sur cet appareil"), findsOneWidget);
  });

  testWidgets("has a back-only, transparent Top App Bar", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();

    final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, Colors.transparent);
  });

  testWidgets("renders correctly against the dark theme", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(theme: RahatiTheme.dark));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets("renders correctly under the Arabic (RTL) locale", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(locale: const Locale("ar")));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(QiblaCompass), findsOneWidget);
  });
}
