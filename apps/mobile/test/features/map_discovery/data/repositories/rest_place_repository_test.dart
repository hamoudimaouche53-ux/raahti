// Traces to: US-01.1.7 (FR-MAP-07), ADR-0008/ADR-0022.
import "dart:convert";

import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/map_discovery/data/datasources/place_local_data_source.dart";
import "package:rahati/features/map_discovery/data/datasources/place_remote_data_source.dart";
import "package:rahati/features/map_discovery/data/local/app_database.dart";
import "package:rahati/features/map_discovery/data/repositories/rest_place_repository.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/repositories/place_repository.dart";

const _center = Coordinates(latitude: 36.75, longitude: 3.06);

Map<String, dynamic> _placeJson(String id) => <String, dynamic>{
  "id": id,
  "placeKind": "station",
  "name": <String, dynamic>{"fr": "F $id", "ar": "A $id", "en": "E $id"},
  "position": <String, dynamic>{
    "type": "Point",
    "coordinates": <double>[3.06, 36.75],
  },
  "pinColor": "green",
  "distanceMeters": 50.0,
  "averageRating": null,
  "reviewCount": 0,
  "isFree": true,
  "tags": <String>[],
};

RestPlaceRepository _repository({
  required http.Client client,
  required AppDatabase db,
}) {
  final remote = PlaceRemoteDataSource(client, baseUrl: "https://api.test");
  final local = PlaceLocalDataSource(db);
  return RestPlaceRepository(remote, local);
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group("RestPlaceRepository", () {
    test("a successful remote fetch returns isFromCache: false and writes "
        "the cache", () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode({
            "data": [_placeJson("1")],
          }),
          200,
        ),
      );
      final repo = _repository(client: client, db: db);

      final snapshot = await repo.getNearbyPlaces(center: _center);

      expect(snapshot.isFromCache, isFalse);
      expect(snapshot.places, hasLength(1));
      expect(snapshot.lastSyncedAt, isNotNull);

      final cached = await PlaceLocalDataSource(db).readCache();
      expect(cached.places, hasLength(1));
      // Second-level precision, not exact equality — SQLite's DateTime
      // storage truncates sub-second precision, which is irrelevant to
      // FR-MAP-07's minute-granularity freshness indicator.
      expect(
        cached.lastSyncedAt?.difference(snapshot.lastSyncedAt!).inSeconds.abs(),
        lessThanOrEqualTo(1),
      );
    });

    test("a remote failure falls back to the cache with isFromCache: true "
        "when a previous fetch had populated it", () async {
      final workingClient = MockClient(
        (request) async => http.Response(
          jsonEncode({
            "data": [_placeJson("1")],
          }),
          200,
        ),
      );
      await _repository(
        client: workingClient,
        db: db,
      ).getNearbyPlaces(center: _center);

      final failingClient = MockClient(
        (request) async => http.Response("server error", 500),
      );
      final snapshot = await _repository(
        client: failingClient,
        db: db,
      ).getNearbyPlaces(center: _center);

      expect(snapshot.isFromCache, isTrue);
      expect(snapshot.places, hasLength(1));
      expect(snapshot.places.single.id, "1");
    });

    test(
      "a remote failure with no cache rethrows the original failure",
      () async {
        final client = MockClient(
          (request) async => http.Response("server error", 500),
        );
        final repo = _repository(client: client, db: db);

        expect(
          () => repo.getNearbyPlaces(center: _center),
          throwsA(isA<PlaceFetchFailure>()),
        );
      },
    );

    test("ApiNotConfiguredFailure with no cache also rethrows", () async {
      final remote = PlaceRemoteDataSource(http.Client(), baseUrl: null);
      final repo = RestPlaceRepository(remote, PlaceLocalDataSource(db));

      expect(
        () => repo.getNearbyPlaces(center: _center),
        throwsA(isA<ApiNotConfiguredFailure>()),
      );
    });
  });
}
