// Diagnostic-only helper — NOT part of the shipped app or the permanent
// test suite — demonstrates US-01.1.4 (debounced search) and US-01.1.5
// (quick filter chips) with real on-device rendering, using injected
// sample data via the same provider-override mechanism the widget tests
// use (no backend exists yet — see docs/phase-3-implementation-log.md).
// Light/Dark/Arabic(RTL) are separate `testWidgets` cases so each can be
// captured independently via external `adb exec-out screencap` while held.
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:rahati/app.dart";
import "package:rahati/core/providers/app_settings_providers.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/places_snapshot.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_providers.dart";

/// See test/support/fake_nearby_places_notifier.dart — duplicated here
/// (rather than a cross-directory relative import) since `nearbyPlacesProvider`
/// is an `AsyncNotifierProvider`, whose `overrideWith` needs a
/// `NearbyPlacesNotifier Function()` factory, not a plain async callback.
class _FakeNearbyPlacesNotifier extends NearbyPlacesNotifier {
  _FakeNearbyPlacesNotifier(this._build);
  final Future<PlacesSnapshot> Function() _build;

  @override
  Future<PlacesSnapshot> build() => _build();
}

const _center = Coordinates(latitude: 36.7538, longitude: 3.0588);

Place _place(
  String id,
  PlaceKind kind,
  PinColor color,
  bool isFree,
  String name,
) => Place(
  id: id,
  placeKind: kind,
  name: LocalizedText(fr: name, ar: "مكان $id", en: name),
  position: _center,
  pinColor: color,
  distanceMeters: 120 + (int.parse(id) * 40),
  averageRating: 4.2,
  reviewCount: 12,
  isFree: isFree,
  tags: const <String>[],
);

final _samplePlaces = [
  _place("1", PlaceKind.station, PinColor.amber, true, "Station Didouche"),
  _place(
    "2",
    PlaceKind.thirdPartyPlace,
    PinColor.green,
    true,
    "WC Gratuit Hydra",
  ),
  _place(
    "3",
    PlaceKind.thirdPartyPlace,
    PinColor.blue,
    false,
    "WC Payant Kouba",
  ),
  _place("4", PlaceKind.station, PinColor.magenta, true, "Slatoki El Biar"),
];

class _DarkThemeModeNotifier extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.dark;
}

class _ArabicLocaleNotifier extends LocaleNotifier {
  @override
  Locale? build() => const Locale("ar");
}

// `List<dynamic>`/`dynamic`, not `List<Override>`/`Override` — `Override`
// isn't exported from `flutter_riverpod`'s public API surface in this
// version.
List<dynamic> _positionOverrides() => [
  userPositionProvider.overrideWith((ref) async => _center),
  userPositionStreamProvider.overrideWith((ref) => Stream.value(_center)),
];

dynamic _nearbyPlacesOverride() => nearbyPlacesProvider.overrideWith(
  () => _FakeNearbyPlacesNotifier(
    () async => PlacesSnapshot(
      places: _samplePlaces,
      lastSyncedAt: DateTime.now(),
      isFromCache: false,
    ),
  ),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    "Light (FR): shows the search bar, filter chips, and a filtered result",
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [..._positionOverrides(), _nearbyPlacesOverride()],
          child: const RahatiApp(),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.enterText(find.byType(TextField).first, "wc");
      await tester.tap(find.text("Gratuit"));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      // Dismiss the keyboard so it doesn't obscure the map in the capture.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      // ignore: avoid_print
      print("HOLD_START");
      await tester.pump(const Duration(seconds: 30));
    },
  );

  testWidgets("Dark (FR): shows the search bar and filter chips", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._positionOverrides(),
          _nearbyPlacesOverride(),
          themeModeProvider.overrideWith(_DarkThemeModeNotifier.new),
        ],
        child: const RahatiApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.text("RAHETI"));
    await tester.pump();
    await tester.pumpAndSettle();

    // ignore: avoid_print
    print("HOLD_START");
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets("RTL (AR): shows the mirrored search bar and filter chips", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._positionOverrides(),
          _nearbyPlacesOverride(),
          localeProvider.overrideWith(_ArabicLocaleNotifier.new),
        ],
        child: const RahatiApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ignore: avoid_print
    print("HOLD_START");
    await tester.pump(const Duration(seconds: 30));
  });
}
