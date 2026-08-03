// Traces to: US-01.2.2, US-01.2.3 — see MockPlaceDetailRepository's doc
// comment (explicitly opt-in stand-in, ADR-0023) for the "why".
import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/data/repositories/mock_place_detail_repository.dart";
import "package:rahati/features/map_discovery/domain/entities/cabin.dart";
import "package:rahati/features/map_discovery/domain/entities/station_detail.dart";
import "package:rahati/features/map_discovery/domain/entities/third_party_place_detail.dart";

void main() {
  group("MockPlaceDetailRepository", () {
    const repo = MockPlaceDetailRepository();

    test(
      "getStationDetail returns cabins covering every occupancy status",
      () async {
        final detail = await repo.getStationDetail("any-id");

        final statuses = detail.cabins.map((c) => c.occupancyStatus).toSet();
        expect(statuses, {
          CabinOccupancyStatus.free,
          CabinOccupancyStatus.occupied,
          CabinOccupancyStatus.outOfService,
        });
      },
    );

    test(
      "getStationDetail includes at least one paid cabin with a price",
      () async {
        final detail = await repo.getStationDetail("any-id");
        final paid = detail.cabins.where((c) => c.isPaid);
        expect(paid, isNotEmpty);
        expect(paid.first.price, isNotNull);
      },
    );

    test("getStationDetail's summary id matches the requested id (shape "
        "fidelity, even though the value is fabricated)", () async {
      final detail = await repo.getStationDetail("station-42");
      expect(detail.summary.id, "station-42");
    });

    test("getThirdPartyPlaceDetail returns a declared status", () async {
      final ThirdPartyPlaceDetail detail = await repo.getThirdPartyPlaceDetail(
        "place-1",
      );
      expect(detail.declaredStatus, isNotNull);
      expect(detail.summary.id, "place-1");
    });

    test("StationDetail's own type carries all fields (regression guard "
        "for the summary/configuration/status/cabins shape)", () async {
      final StationDetail detail = await repo.getStationDetail("s1");
      expect(detail.configuration, isNotNull);
      expect(detail.status, isNotNull);
    });
  });
}
