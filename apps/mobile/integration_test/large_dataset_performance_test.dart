// Diagnostic-only helper — NOT part of the shipped app or the permanent
// test suite — EPIC-01 close-out "Performance Verification": exercises
// MapScreen with a synthetic 300-place dataset (well past any realistic
// single `GET /places/nearby` response) on the real device, timing zoom/
// pan/filter interactions and printing the results for `adb shell dumpsys
// meminfo`/`gfxinfo` to be sampled around (see docs/phase-3-implementation-log.md
// for the captured figures — device profiling numbers aren't meaningfully
// assertable in an automated test, only measurable and reported).
import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:rahati/app.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/places_snapshot.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_providers.dart";

class _FakeNearbyPlacesNotifier extends NearbyPlacesNotifier {
  _FakeNearbyPlacesNotifier(this._build);
  final Future<PlacesSnapshot> Function() _build;

  @override
  Future<PlacesSnapshot> build() => _build();
}

const _center = Coordinates(latitude: 36.7538, longitude: 3.0588);

List<Place> _syntheticPlaces(int count) {
  final random = Random(7);
  return List<Place>.generate(count, (i) {
    final double lat = _center.latitude + (random.nextDouble() - 0.5) * 0.12;
    final double lng = _center.longitude + (random.nextDouble() - 0.5) * 0.12;
    return Place(
      id: "p$i",
      placeKind: i.isEven ? PlaceKind.station : PlaceKind.thirdPartyPlace,
      name: LocalizedText(fr: "Lieu $i", ar: "مكان $i", en: "Place $i"),
      position: Coordinates(latitude: lat, longitude: lng),
      pinColor: PinColor.values[i % PinColor.values.length],
      distanceMeters: random.nextDouble() * 4000,
      averageRating: random.nextDouble() * 5,
      reviewCount: i % 9,
      isFree: i.isEven,
      tags: const <String>[],
    );
  });
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("MapScreen stays responsive with 300 synthetic places (zoom, "
      "pan, filter)", (tester) async {
    final places = _syntheticPlaces(300);

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
                places: places,
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

    final Stopwatch initialRender = Stopwatch()..start();
    await tester.pump();
    initialRender.stop();
    // ignore: avoid_print
    print(
      "PERF initial-frame-with-300-places-ms=${initialRender.elapsedMilliseconds}",
    );

    final Stopwatch zoomTimer = Stopwatch()..start();
    for (var i = 0; i < 5; i++) {
      await tester.drag(find.byType(FlutterMap), const Offset(0, -40));
      await tester.pump();
    }
    zoomTimer.stop();
    // ignore: avoid_print
    print("PERF 5-pan-gestures-ms=${zoomTimer.elapsedMilliseconds}");

    final Stopwatch filterTimer = Stopwatch()..start();
    await tester.enterText(find.byType(TextField).first, "lieu 1");
    await tester.pump(const Duration(milliseconds: 400));
    filterTimer.stop();
    // ignore: avoid_print
    print(
      "PERF debounced-search-over-300-places-ms=${filterTimer.elapsedMilliseconds}",
    );

    // Hold briefly for an external `adb shell dumpsys meminfo`/`gfxinfo`
    // sample while 300 places are live on-screen.
    await tester.pump(const Duration(seconds: 8));
  });
}
