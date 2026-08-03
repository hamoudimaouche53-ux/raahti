// Traces to: SCR-008, docs/design/wireframes/mobile-slatoki.md#scr-008-slatoki-tab-list--qibla-widget-flagship.
// US-02.1.1 + US-02.1.2 + US-02.1.3 + US-02.1.4 scope — the Slatoki
// Tent-Status Card (US-02.1.5) is a separate, not-yet-implemented story.
import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/core/theme/color_tokens.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_providers.dart";
import "package:rahati/features/slatoki/domain/entities/slatoki_place.dart";
import "package:rahati/features/slatoki/domain/entities/women_verification_level.dart";
import "package:rahati/features/slatoki/domain/repositories/slatoki_place_repository.dart";
import "package:rahati/features/slatoki/presentation/providers/qibla_providers.dart";
import "package:rahati/features/slatoki/presentation/providers/slatoki_place_providers.dart";
import "package:rahati/features/slatoki/presentation/screens/slatoki_screen.dart";
import "package:rahati/features/slatoki/presentation/widgets/qibla_compass.dart";
import "package:rahati/features/slatoki/presentation/widgets/slatoki_place_detail_sheet.dart";
import "package:rahati/l10n/app_localizations.dart";

const _center = Coordinates(latitude: 36.7538, longitude: 3.0588);

SlatokiPlace _place(String id, {List<String> tags = const ["prayer"]}) =>
    SlatokiPlace(
      place: Place(
        id: id,
        placeKind: PlaceKind.thirdPartyPlace,
        name: LocalizedText(fr: "Lieu $id", ar: "مكان $id", en: "Place $id"),
        position: _center,
        pinColor: PinColor.magenta,
        distanceMeters: 100,
        averageRating: null,
        reviewCount: 0,
        isFree: true,
        tags: tags,
      ),
      womenVerificationLevel: WomenVerificationLevel.generic,
    );

// `List<dynamic>`, not `List<Override>` — `Override` isn't exported from
// `flutter_riverpod`'s public API surface in this version (same caveat as
// integration_test/map_recenter_offline_screenshot_test.dart).
Widget _wrap({
  required List<dynamic> overrides,
  ThemeData? theme,
  Locale locale = const Locale("fr"),
}) {
  return ProviderScope(
    overrides: [
      // Never touches the real `flutter_compass` platform channel — see
      // qibla_compass_test.dart.
      rawCompassEventsProvider.overrideWithValue(const Stream.empty()),
      userPositionProvider.overrideWith((ref) async => _center),
      ...overrides,
    ],
    child: MaterialApp(
      theme: theme ?? RahatiTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const SlatokiScreen(),
    ),
  );
}

void main() {
  testWidgets("shows the bilingual 'Slatoki صلاتكِ' title", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        overrides: [
          slatokiPlacesProvider.overrideWith((ref) async => const []),
        ],
      ),
    );
    await tester.pump();

    expect(find.text("Slatoki صلاتكِ"), findsOneWidget);
  });

  testWidgets("the AppBar carries a slatoki-functional-color accent underline "
      "(distinguishing this tab from the rest of the app, per the wireframe)", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        overrides: [
          slatokiPlacesProvider.overrideWith((ref) async => const []),
        ],
      ),
    );
    await tester.pump();

    final BuildContext context = tester.element(find.byType(SlatokiScreen));
    final RahatiFunctionalColors colors = Theme.of(
      context,
    ).extension<RahatiFunctionalColors>()!;

    final Container underline = tester.widget<Container>(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(Container),
      ),
    );
    expect(underline.color, colors.slatoki);
  });

  testWidgets("shows the compact Qibla Compass widget card pinned near the top "
      "(US-02.1.2)", (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        overrides: [
          slatokiPlacesProvider.overrideWith((ref) async => const []),
        ],
      ),
    );
    await tester.pump();

    final QiblaCompass compass = tester.widget<QiblaCompass>(
      find.byType(QiblaCompass),
    );
    expect(compass.mode, QiblaCompassMode.compact);
    expect(compass.onTap, isNotNull);
  });

  testWidgets("shows the filter tab row (US-02.1.3)", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        overrides: [
          slatokiPlacesProvider.overrideWith((ref) async => const []),
        ],
      ),
    );
    await tester.pump();

    expect(find.text("Prière seule"), findsOneWidget);
    expect(find.text("Wudu seul"), findsOneWidget);
    expect(find.text("Prière + Wudu"), findsOneWidget);
  });

  testWidgets("shows a loading state while the places fetch is pending", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        overrides: [
          slatokiPlacesProvider.overrideWith(
            (ref) => Completer<List<SlatokiPlace>>().future,
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text("Recherche des espaces Slatoki…"), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    "shows the 'not configured' error banner on ApiNotConfiguredFailure",
    (WidgetTester tester) async {
      // Riverpod 3.x retries a failed FutureProvider build automatically
      // (`ProviderContainer.defaultRetry`, exponential backoff starting at
      // 200ms) unless the thrown error is an `Error`/`ProviderException` —
      // `SlatokiApiNotConfiguredFailure` (an `Exception`) doesn't qualify,
      // so without disabling it here the provider would sit in
      // `AsyncLoading` (with the error attached as retry context, not yet
      // surfaced) for several real seconds before this test could observe
      // `AsyncError`. Retrying a "no backend configured" failure can never
      // succeed regardless, so disabling retry is the correct fix for the
      // test, not a workaround for a flaky one.
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          rawCompassEventsProvider.overrideWithValue(const Stream.empty()),
          userPositionProvider.overrideWith((ref) async => _center),
          slatokiPlacesProvider.overrideWith((ref) {
            throw const SlatokiApiNotConfiguredFailure();
          }),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: RahatiTheme.light,
            locale: const Locale("fr"),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const SlatokiScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.text(
          "Aucun serveur configuré — les espaces Slatoki ne peuvent pas être chargés.",
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets("shows the wireframe-defined empty state when the (filtered) "
      "list is empty", (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        overrides: [
          slatokiPlacesProvider.overrideWith((ref) async => const []),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text("Aucun espace Slatoki à proximité"), findsOneWidget);
  });

  testWidgets(
    "shows fetched places as a list, narrowed by the active filter tab",
    (WidgetTester tester) async {
      final prayerPlace = _place("1", tags: const ["prayer"]);
      final wuduPlace = _place("2", tags: const ["wudu"]);
      await tester.pumpWidget(
        _wrap(
          overrides: [
            slatokiPlacesProvider.overrideWith(
              (ref) async => [prayerPlace, wuduPlace],
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      // Default tab is "Prière seule" — only the prayer-tagged place shows.
      expect(find.text("Lieu 1"), findsOneWidget);
      expect(find.text("Lieu 2"), findsNothing);

      // Not pumpAndSettle(): the compact compass card's calibrating pulse
      // animation repeats indefinitely (its own stream is empty in this
      // test), so nothing would ever settle — see
      // nav_shell_screenshot_test.dart's `_settle` rationale.
      await tester.tap(find.text("Wudu seul"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.text("Lieu 1"), findsNothing);
      expect(find.text("Lieu 2"), findsOneWidget);
    },
  );

  testWidgets("tapping a place opens the SlatokiPlaceDetailSheet (US-02.1.4)", (
    WidgetTester tester,
  ) async {
    final prayerPlace = _place("1", tags: const ["prayer"]);
    await tester.pumpWidget(
      _wrap(
        overrides: [
          slatokiPlacesProvider.overrideWith((ref) async => [prayerPlace]),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text("Lieu 1"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SlatokiPlaceDetailSheet), findsOneWidget);
  });

  testWidgets("renders correctly against the dark theme", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        overrides: [
          slatokiPlacesProvider.overrideWith((ref) async => const []),
        ],
        theme: RahatiTheme.dark,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text("Slatoki صلاتكِ"), findsOneWidget);
  });

  testWidgets("renders correctly under the Arabic (RTL) locale", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        overrides: [
          slatokiPlacesProvider.overrideWith((ref) async => const []),
        ],
        locale: const Locale("ar"),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      Directionality.of(
        tester.element(find.text("لا توجد مساحة صلاتكِ قريبة منك")),
      ),
      TextDirection.rtl,
    );
  });
}
