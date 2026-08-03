// Diagnostic-only helper — NOT part of the shipped app or the permanent
// test suite — demonstrates US-01.1.2 (color-coded/clustered markers) and
// US-01.1.3 (tap-to-detail) with real on-device rendering, using injected
// sample data via the same provider-override mechanism the widget tests
// use (no backend exists yet — see docs/phase-3-implementation-log.md).
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:rahati/app.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/places_snapshot.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_providers.dart";
import "package:rahati/features/map_discovery/presentation/widgets/place_marker.dart";

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

Place _place(String id, PlaceKind kind, PinColor color, Coordinates pos) =>
    Place(
      id: id,
      placeKind: kind,
      name: LocalizedText(fr: "Lieu $id", ar: "مكان $id", en: "Place $id"),
      position: pos,
      pinColor: color,
      distanceMeters: 120,
      averageRating: id == "1" ? 4.6 : null,
      reviewCount: id == "1" ? 32 : 0,
      isFree: color == PinColor.green,
      tags: id == "1" ? const ["women_confirmed", "wudu"] : const [],
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("shows color-coded markers, a cluster, and the detail sheet", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPositionProvider.overrideWith((ref) async => _center),
          userPositionStreamProvider.overrideWith(
            (ref) => Stream.value(_center),
          ),
          nearbyPlacesProvider.overrideWith(
            () => _FakeNearbyPlacesNotifier(
              () async => PlacesSnapshot(
                places: [
                  _place("1", PlaceKind.station, PinColor.amber, _center),
                  _place(
                    "2",
                    PlaceKind.thirdPartyPlace,
                    PinColor.green,
                    const Coordinates(latitude: 36.758, longitude: 3.062),
                  ),
                  // Two places at the same spot -> renders as one ClusterMarker.
                  _place(
                    "3",
                    PlaceKind.station,
                    PinColor.magenta,
                    const Coordinates(latitude: 36.748, longitude: 3.055),
                  ),
                  _place(
                    "4",
                    PlaceKind.thirdPartyPlace,
                    PinColor.blue,
                    const Coordinates(latitude: 36.748, longitude: 3.055),
                  ),
                ],
                lastSyncedAt: DateTime.now(),
                isFromCache: false,
              ),
            ),
          ),
        ],
        child: const RahatiApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Tap the single amber (RAHETI unit) marker to open the detail sheet.
    await tester.tap(find.byType(PlaceMarker).first);
    await tester.pumpAndSettle();

    // Hold for external `adb screencap`.
    await tester.pump(const Duration(seconds: 15));
  });
}
