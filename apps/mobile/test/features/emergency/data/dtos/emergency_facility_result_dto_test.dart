import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/emergency/data/dtos/emergency_facility_result_dto.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";

Map<String, dynamic> _placeJson() => <String, dynamic>{
  "id": "place-1",
  "placeKind": "station",
  "name": <String, dynamic>{
    "fr": "Station Didouche",
    "ar": "محطة ديدوش",
    "en": "Didouche Station",
  },
  "position": <String, dynamic>{
    "coordinates": <double>[3.06, 36.75],
  },
  "pinColor": "green",
  "distanceMeters": 180.0,
  "averageRating": null,
  "reviewCount": 0,
  "isFree": true,
  "tags": <String>[],
};

void main() {
  group("EmergencyFacilityResultDto", () {
    test("parses a full JSON payload", () {
      final dto = EmergencyFacilityResultDto.fromJson(<String, dynamic>{
        "place": _placeJson(),
        "nearestCabinId": "cabin-1",
        "discountEligible": true,
      });

      expect(dto.place.id, "place-1");
      expect(dto.nearestCabinId, "cabin-1");
      expect(dto.discountEligible, isTrue);
    });

    test("parses a null nearestCabinId", () {
      final dto = EmergencyFacilityResultDto.fromJson(<String, dynamic>{
        "place": _placeJson(),
        "nearestCabinId": null,
        "discountEligible": false,
      });

      expect(dto.nearestCabinId, isNull);
      expect(dto.discountEligible, isFalse);
    });

    test("toEntity() maps the place and computes etaMinutesOnFoot from "
        "distanceMeters at ~83.3 m/min", () {
      final dto = EmergencyFacilityResultDto.fromJson(<String, dynamic>{
        "place": _placeJson(),
        "nearestCabinId": "cabin-1",
        "discountEligible": true,
      });

      final entity = dto.toEntity();

      expect(entity.place, isA<Place>());
      expect(entity.place.distanceMeters, 180);
      // 180 / 83.3 = 2.16... -> rounds to 2.
      expect(entity.etaMinutesOnFoot, 2);
      expect(entity.nearestCabinId, "cabin-1");
      expect(entity.discountEligible, isTrue);
    });

    test("toEntity() rounds a larger distance to the nearest whole minute", () {
      final Map<String, dynamic> json = _placeJson();
      json["distanceMeters"] = 1000.0;
      final dto = EmergencyFacilityResultDto.fromJson(<String, dynamic>{
        "place": json,
        "nearestCabinId": null,
        "discountEligible": false,
      });

      // 1000 / 83.3 = 12.0048... -> rounds to 12.
      expect(dto.toEntity().etaMinutesOnFoot, 12);
    });
  });
}
