import "cabin.dart";

/// A single cabin's occupancy change, as broadcast over the
/// `station:{stationId}:cabins` Realtime channel (FR-PAY-05,
/// docs/api/api-architecture.md §10). Deliberately narrower than a full
/// [Cabin] — the channel only carries what actually changes in real time
/// (occupancy); code/type/pricing are static and stay sourced from the
/// initial `GET /stations/{id}` fetch.
class CabinOccupancyUpdate {
  const CabinOccupancyUpdate({
    required this.cabinId,
    required this.occupancyStatus,
  });

  final String cabinId;
  final CabinOccupancyStatus occupancyStatus;
}
