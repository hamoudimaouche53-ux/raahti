// Traces to: US-01.1.7 (FR-MAP-07), ADR-0008/ADR-0022.
import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/data/datasources/place_local_data_source.dart";
import "package:rahati/features/map_discovery/data/local/app_database.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";

Place _place(String id, {List<String> tags = const <String>[]}) => Place(
  id: id,
  placeKind: PlaceKind.station,
  name: LocalizedText(fr: "Station $id", ar: "محطة $id", en: "Station $id"),
  position: const Coordinates(latitude: 36.75, longitude: 3.06),
  pinColor: PinColor.amber,
  distanceMeters: 120,
  averageRating: id == "1" ? 4.5 : null,
  reviewCount: id == "1" ? 10 : 0,
  isFree: true,
  tags: tags,
);

void main() {
  late AppDatabase db;
  late PlaceLocalDataSource dataSource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = PlaceLocalDataSource(db);
  });

  tearDown(() => db.close());

  group("PlaceLocalDataSource", () {
    test("readCache returns an empty list and a null timestamp when never "
        "populated", () async {
      final result = await dataSource.readCache();

      expect(result.places, isEmpty);
      expect(result.lastSyncedAt, isNull);
    });

    test("cachePlaces then readCache round-trips every field, including "
        "tags", () async {
      final syncedAt = DateTime(2026, 7, 31, 18, 30);
      await dataSource.cachePlaces([
        _place("1", tags: const ["women_confirmed", "wudu"]),
      ], syncedAt);

      final result = await dataSource.readCache();

      expect(result.lastSyncedAt, syncedAt);
      expect(result.places, hasLength(1));
      final Place roundTripped = result.places.single;
      expect(roundTripped.id, "1");
      expect(roundTripped.name.fr, "Station 1");
      expect(roundTripped.name.ar, "محطة 1");
      expect(roundTripped.placeKind, PlaceKind.station);
      expect(roundTripped.pinColor, PinColor.amber);
      expect(roundTripped.averageRating, 4.5);
      expect(roundTripped.reviewCount, 10);
      expect(roundTripped.tags, ["women_confirmed", "wudu"]);
    });

    test(
      "a place with no tags round-trips to an empty list, not [\"\"]",
      () async {
        await dataSource.cachePlaces([_place("1")], DateTime(2026, 1, 1));

        final result = await dataSource.readCache();

        expect(result.places.single.tags, isEmpty);
      },
    );

    test(
      "cachePlaces replaces the previous cache entirely, not merges",
      () async {
        await dataSource.cachePlaces([_place("1")], DateTime(2026, 1, 1));
        await dataSource.cachePlaces([_place("2")], DateTime(2026, 1, 2));

        final result = await dataSource.readCache();

        expect(result.places.map((p) => p.id), ["2"]);
        expect(result.lastSyncedAt, DateTime(2026, 1, 2));
      },
    );
  });
}
