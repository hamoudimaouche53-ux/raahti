import "dart:async";

import "../../domain/entities/cabin.dart";
import "../../domain/entities/cabin_occupancy_update.dart";
import "../../domain/repositories/cabin_realtime_repository.dart";

/// **Explicitly-opt-in mock adapter** for [CabinRealtimeRepository] — not
/// wired by default (reuses `AppEnv.useMockPlaceDetail`; see
/// `MockPlaceDetailRepository`'s doc comment and ADR-0023). A live-update
/// demo has no meaning without `MockPlaceDetailRepository`'s fabricated
/// cabin list to update in the first place, so this shares that flag
/// rather than adding a second, independently-toggleable one for the
/// same underlying demo.
///
/// Periodically flips `$stationId-cabin-2` (the paid cabin
/// `MockPlaceDetailRepository` seeds as `occupied`) back and forth
/// between `occupied`/`free` — a believable "someone just left" /
/// "someone just entered" simulation, fabricated and clearly labeled the
/// same way every other mock in this codebase is.
class MockCabinRealtimeRepository implements CabinRealtimeRepository {
  MockCabinRealtimeRepository({
    this.interval = const Duration(seconds: 4),
  });

  final Duration interval;

  @override
  Stream<CabinOccupancyUpdate> watchStationCabins(String stationId) {
    final String cabinId = "$stationId-cabin-2";
    return Stream.periodic(interval, (tick) {
      final bool free = tick.isEven;
      return CabinOccupancyUpdate(
        cabinId: cabinId,
        occupancyStatus: free
            ? CabinOccupancyStatus.free
            : CabinOccupancyStatus.occupied,
      );
    });
  }
}
