// Traces to: US-01.1.7 (FR-MAP-07), ADR-0008/ADR-0022.
import "package:fake_async/fake_async.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/places_snapshot.dart";
import "package:rahati/features/map_discovery/domain/repositories/place_repository.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_providers.dart";

const _center = Coordinates(latitude: 36.75, longitude: 3.06);

Place _place(String id) => Place(
  id: id,
  placeKind: PlaceKind.station,
  name: const LocalizedText(fr: "F", ar: "A", en: "E"),
  position: _center,
  pinColor: PinColor.amber,
  distanceMeters: 100,
  averageRating: null,
  reviewCount: 0,
  isFree: true,
  tags: const <String>[],
);

/// A repository whose `getNearbyPlaces` result is swappable mid-test —
/// lets a test simulate "offline, then connectivity returns" without any
/// real network or timing dependency beyond [FakeAsync].
class _ScriptedRepository implements PlaceRepository {
  int callCount = 0;
  Future<PlacesSnapshot> Function()? next;

  @override
  Future<PlacesSnapshot> getNearbyPlaces({
    required Coordinates center,
    double radiusMeters = 2000,
  }) {
    callCount++;
    final Future<PlacesSnapshot> Function()? script = next;
    if (script == null) {
      throw StateError(
        "_ScriptedRepository.next was not set for call #$callCount",
      );
    }
    return script();
  }
}

void main() {
  test("falls back to cached data, then recovers automatically once the "
      "repository succeeds again on retry", () {
    fakeAsync((async) {
      final repo = _ScriptedRepository()
        ..next = () async => PlacesSnapshot(
          places: [_place("cached")],
          lastSyncedAt: DateTime(2026, 1, 1),
          isFromCache: true,
        );

      final container = ProviderContainer(
        overrides: [
          userPositionProvider.overrideWith((ref) async => _center),
          placeRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      container.listen(nearbyPlacesProvider, (previous, next) {});
      async.flushMicrotasks();

      final AsyncValue<PlacesSnapshot> initial = container.read(
        nearbyPlacesProvider,
      );
      expect(initial.value?.isFromCache, isTrue);
      expect(initial.value?.places.single.id, "cached");
      expect(container.read(isReconnectingNearbyPlacesProvider), isFalse);

      // Connectivity returns before the next scheduled retry fires.
      repo.next = () async => PlacesSnapshot(
        places: [_place("live")],
        lastSyncedAt: DateTime(2026, 1, 2),
        isFromCache: false,
      );

      async.elapse(NearbyPlacesNotifier.retryInterval);
      async.flushMicrotasks();

      final AsyncValue<PlacesSnapshot> recovered = container.read(
        nearbyPlacesProvider,
      );
      expect(recovered.value?.isFromCache, isFalse);
      expect(recovered.value?.places.single.id, "live");
      expect(container.read(isReconnectingNearbyPlacesProvider), isFalse);
      expect(repo.callCount, 2);
    });
  });

  test("keeps retrying (does not give up after one failed retry)", () {
    fakeAsync((async) {
      final repo = _ScriptedRepository()
        ..next = () async => PlacesSnapshot(
          places: [_place("cached")],
          lastSyncedAt: DateTime(2026, 1, 1),
          isFromCache: true,
        );

      final container = ProviderContainer(
        overrides: [
          userPositionProvider.overrideWith((ref) async => _center),
          placeRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      container.listen(nearbyPlacesProvider, (previous, next) {});
      async.flushMicrotasks();
      expect(repo.callCount, 1);

      // First retry still fails/offline.
      async.elapse(NearbyPlacesNotifier.retryInterval);
      async.flushMicrotasks();
      expect(repo.callCount, 2);
      expect(container.read(nearbyPlacesProvider).value?.isFromCache, isTrue);

      // Second retry succeeds.
      repo.next = () async => PlacesSnapshot(
        places: [_place("live")],
        lastSyncedAt: DateTime(2026, 1, 3),
        isFromCache: false,
      );
      async.elapse(NearbyPlacesNotifier.retryInterval);
      async.flushMicrotasks();

      expect(repo.callCount, 3);
      expect(container.read(nearbyPlacesProvider).value?.isFromCache, isFalse);
    });
  });
}
