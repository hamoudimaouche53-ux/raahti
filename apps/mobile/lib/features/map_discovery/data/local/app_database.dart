import "dart:io";

import "package:drift/drift.dart";
import "package:drift/native.dart";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";

part "app_database.g.dart";

/// The offline-first local read cache (ADR-0008, finalized by ADR-0022) —
/// one row per place from the most recent successful `GET /places/nearby`
/// fetch, plus a single-row sync timestamp. Read-only from the app's
/// perspective in the sense RAH-DOC-005 requires: this cache is never a
/// write-queue (payment/unlock stay strictly online, per ADR-0008) — it
/// exists solely so [PlaceLocalDataSource] can serve FR-MAP-07's "last
/// cached set of nearby places with a freshness indicator" when a remote
/// fetch fails.
class CachedPlaces extends Table {
  TextColumn get id => text()();
  TextColumn get placeKind => text()();
  TextColumn get nameFr => text()();
  TextColumn get nameAr => text()();
  TextColumn get nameEn => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get pinColor => text()();
  RealColumn get distanceMeters => real()();
  RealColumn get averageRating => real().nullable()();
  IntColumn get reviewCount => integer()();
  BoolColumn get isFree => boolean()();
  // Comma-joined — the tag vocabulary is a small closed set (erd.md §3.5)
  // with no commas in any value, so no escaping is needed.
  TextColumn get tags => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Single-row table (`id` is always 0) recording when [CachedPlaces] was
/// last successfully refreshed from the backend.
class CacheMeta extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [CachedPlaces, CacheMeta])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final Directory dbFolder = await getApplicationDocumentsDirectory();
      final File file = File(p.join(dbFolder.path, "rahati_cache.sqlite"));
      return NativeDatabase.createInBackground(file);
    });
  }
}
