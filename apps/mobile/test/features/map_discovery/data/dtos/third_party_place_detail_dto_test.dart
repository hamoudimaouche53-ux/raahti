// Traces to: US-01.2.2 (FR-PLC-02).
import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/data/dtos/third_party_place_detail_dto.dart";
import "package:rahati/features/map_discovery/domain/entities/third_party_place_detail.dart";

Map<String, dynamic> _json({
  String placeType = "mosque",
  String declaredStatus = "open",
  String statusSource = "community",
}) => {
  "id": "p1",
  "placeKind": "third_party_place",
  "name": {"fr": "Mosquée F", "ar": "مسجد", "en": "Mosque E"},
  "position": {
    "type": "Point",
    "coordinates": [3.06, 36.75],
  },
  "pinColor": "green",
  // No "distanceMeters" — GET /third-party-places/{id} never includes it,
  // same reasoning as station_detail_dto_test.dart's fixture.
  "averageRating": null,
  "reviewCount": 0,
  "isFree": true,
  "tags": <String>[],
  "placeType": placeType,
  "declaredStatus": declaredStatus,
  "statusSource": statusSource,
};

void main() {
  group("ThirdPartyPlaceDetailDto", () {
    test(
      "parses successfully with no 'distanceMeters' in the payload "
      "(regression: real GET /third-party-places/{id} responses never "
      "include it; found crashing on a real device against the real backend)",
      () {
        expect(
          () => ThirdPartyPlaceDetailDto.fromJson(_json()).toEntity(),
          returnsNormally,
        );
        final entity = ThirdPartyPlaceDetailDto.fromJson(_json()).toEntity();
        expect(entity.summary.distanceMeters, 0);
      },
    );

    test("maps the snake_case wire value 'gas_station' to "
        "ThirdPartyPlaceType.gasStation", () {
      final entity = ThirdPartyPlaceDetailDto.fromJson(
        _json(placeType: "gas_station"),
      ).toEntity();
      expect(entity.placeType, ThirdPartyPlaceType.gasStation);
    });

    test("maps declaredStatus values", () {
      expect(
        ThirdPartyPlaceDetailDto.fromJson(
          _json(declaredStatus: "closed"),
        ).toEntity().declaredStatus,
        DeclaredStatus.closed,
      );
      expect(
        ThirdPartyPlaceDetailDto.fromJson(
          _json(declaredStatus: "unknown"),
        ).toEntity().declaredStatus,
        DeclaredStatus.unknown,
      );
    });

    test("maps the snake_case wire value 'owner_declared' to "
        "StatusSource.ownerDeclared", () {
      final entity = ThirdPartyPlaceDetailDto.fromJson(
        _json(statusSource: "owner_declared"),
      ).toEntity();
      expect(entity.statusSource, StatusSource.ownerDeclared);
    });
  });
}
