import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/places_snapshot.dart";
import "package:rahati/features/map_discovery/domain/repositories/place_repository.dart";
import "package:rahati/features/map_discovery/domain/usecases/get_nearby_places.dart";

class _FakePlaceRepository implements PlaceRepository {
  _FakePlaceRepository({this.result, this.failure});

  final List<Place>? result;
  final PlaceRepositoryFailure? failure;
  Coordinates? lastCenter;
  double? lastRadius;

  @override
  Future<PlacesSnapshot> getNearbyPlaces({
    required Coordinates center,
    double radiusMeters = 2000,
  }) async {
    lastCenter = center;
    lastRadius = radiusMeters;
    if (failure != null) throw failure!;
    return PlacesSnapshot(
      places: result ?? const <Place>[],
      lastSyncedAt: DateTime(2026, 1, 1),
      isFromCache: false,
    );
  }
}

Place _place(String id) => Place(
  id: id,
  placeKind: PlaceKind.station,
  name: const LocalizedText(fr: "F", ar: "A", en: "E"),
  position: const Coordinates(latitude: 36.75, longitude: 3.06),
  pinColor: PinColor.amber,
  distanceMeters: 100,
  averageRating: null,
  reviewCount: 0,
  isFree: false,
  tags: const <String>[],
);

void main() {
  group("GetNearbyPlaces", () {
    const center = Coordinates(latitude: 36.75, longitude: 3.06);

    test("delegates to the repository with the given center/radius", () async {
      final repo = _FakePlaceRepository(result: [_place("1"), _place("2")]);
      final usecase = GetNearbyPlaces(repo);

      final result = await usecase(center: center, radiusMeters: 500);

      expect(result.places, hasLength(2));
      expect(result.isFromCache, isFalse);
      expect(repo.lastCenter, center);
      expect(repo.lastRadius, 500);
    });

    test("defaults radiusMeters to 2000 when not specified", () async {
      final repo = _FakePlaceRepository();
      final usecase = GetNearbyPlaces(repo);

      await usecase(center: center);

      expect(repo.lastRadius, 2000);
    });

    test("propagates repository failures", () async {
      final repo = _FakePlaceRepository(
        failure: const ApiNotConfiguredFailure(),
      );
      final usecase = GetNearbyPlaces(repo);

      expect(
        () => usecase(center: center),
        throwsA(isA<ApiNotConfiguredFailure>()),
      );
    });
  });
}
