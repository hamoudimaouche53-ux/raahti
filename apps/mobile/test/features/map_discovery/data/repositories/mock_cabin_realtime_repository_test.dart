import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/data/repositories/mock_cabin_realtime_repository.dart";
import "package:rahati/features/map_discovery/domain/entities/cabin.dart";
import "package:rahati/features/map_discovery/domain/entities/cabin_occupancy_update.dart";

void main() {
  group("MockCabinRealtimeRepository", () {
    test(
      "emits alternating free/occupied updates for the station's mock "
      "paid cabin (cabin-2)",
      () async {
        final repository = MockCabinRealtimeRepository(
          interval: const Duration(milliseconds: 10),
        );

        final updates = await repository
            .watchStationCabins("s1")
            .take(3)
            .toList();

        expect(updates, hasLength(3));
        for (final CabinOccupancyUpdate update in updates) {
          expect(update.cabinId, "s1-cabin-2");
        }
        expect(updates[0].occupancyStatus, CabinOccupancyStatus.free);
        expect(updates[1].occupancyStatus, CabinOccupancyStatus.occupied);
        expect(updates[2].occupancyStatus, CabinOccupancyStatus.free);
      },
    );
  });
}
