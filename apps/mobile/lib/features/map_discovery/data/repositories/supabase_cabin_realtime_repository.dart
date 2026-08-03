import "dart:async";

import "package:supabase_flutter/supabase_flutter.dart";

import "../../domain/entities/cabin.dart";
import "../../domain/entities/cabin_occupancy_update.dart";
import "../../domain/repositories/cabin_realtime_repository.dart";

/// [CabinRealtimeRepository] implementation backed by Supabase Realtime
/// (ADR-0005) — subscribes to `UPDATE`s on the `cabin` table
/// (docs/erd/erd.md §"CABIN"), filtered to the given station, per
/// docs/api/api-architecture.md §10's `station:{stationId}:cabins`
/// channel-naming convention.
///
/// The wire payload's `newRecord` uses the **database's own snake_case
/// column names** (`occupancy_status`) — a Postgres change payload, not
/// a `GET /stations/{id}` JSON response — deliberately not reusing
/// `CabinDto`, which maps the REST API's camelCase contract instead.
class SupabaseCabinRealtimeRepository implements CabinRealtimeRepository {
  const SupabaseCabinRealtimeRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<CabinOccupancyUpdate> watchStationCabins(String stationId) {
    late final StreamController<CabinOccupancyUpdate> controller;
    late final RealtimeChannel channel;

    controller = StreamController<CabinOccupancyUpdate>(
      onListen: () {
        channel = _client.channel("station:$stationId:cabins")
          ..onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: "public",
            table: "cabin",
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: "station_id",
              value: stationId,
            ),
            callback: (payload) {
              final update = _toUpdate(payload.newRecord);
              if (update != null) controller.add(update);
            },
          )
          ..subscribe();
      },
      onCancel: () => _client.removeChannel(channel),
    );

    return controller.stream;
  }

  CabinOccupancyUpdate? _toUpdate(Map<String, dynamic> newRecord) {
    final String? cabinId = newRecord["id"] as String?;
    final String? status = newRecord["occupancy_status"] as String?;
    if (cabinId == null || status == null) return null;

    return CabinOccupancyUpdate(
      cabinId: cabinId,
      occupancyStatus: switch (status) {
        "free" => CabinOccupancyStatus.free,
        "occupied" => CabinOccupancyStatus.occupied,
        "out_of_service" => CabinOccupancyStatus.outOfService,
        _ => CabinOccupancyStatus.outOfService,
      },
    );
  }
}
