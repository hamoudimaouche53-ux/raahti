import "../entities/cabin_occupancy_update.dart";

/// Port for the `station:{stationId}:cabins` Realtime channel (US-04.5,
/// FR-PAY-05, docs/api/api-architecture.md §10) — Supabase Realtime
/// (Postgres logical replication over WebSocket), not a polling REST
/// endpoint. Scoped to `map_discovery` (not `access_payment`) because
/// cabin occupancy is displayed via [Cabin]/`StationDetail`, which this
/// feature already owns (US-01.2.2).
///
/// Deliberately a raw [Stream], not an `AsyncNotifier` — the presentation
/// layer (`_StationCabins`) is what accumulates a running set of live
/// overrides on top of the initially-fetched cabin list; this port only
/// needs to emit each change as it arrives.
abstract interface class CabinRealtimeRepository {
  /// Never completes on its own — the caller cancels the subscription
  /// (e.g. by disposing the widget/provider watching it) to stop
  /// listening, closing the underlying channel.
  Stream<CabinOccupancyUpdate> watchStationCabins(String stationId);
}
