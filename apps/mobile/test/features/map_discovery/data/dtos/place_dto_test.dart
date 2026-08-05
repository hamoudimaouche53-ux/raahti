import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/data/dtos/place_dto.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";

Map<String, dynamic> _stationJson({String? en}) => <String, dynamic>{
  "id": "11111111-1111-1111-1111-111111111111",
  "placeKind": "station",
  "name": <String, dynamic>{
    "fr": "Station Didouche",
    "ar": "محطة ديدوش",
    "en": ?en,
  },
  "position": <String, dynamic>{
    "type": "Point",
    "coordinates": <double>[3.06, 36.75], // [lng, lat]
  },
  "pinColor": "amber",
  "distanceMeters": 180.5,
  "averageRating": 4.6,
  "reviewCount": 32,
  "isFree": false,
  "tags": <String>["women_confirmed", "wudu"],
};

void main() {
  group("PlaceDto.fromJson", () {
    test(
      "parses a full station payload (matching openapi.yaml PlaceSummary)",
      () {
        final dto = PlaceDto.fromJson(_stationJson(en: "Didouche Station"));

        expect(dto.id, "11111111-1111-1111-1111-111111111111");
        expect(dto.placeKind, "station");
        expect(dto.name.fr, "Station Didouche");
        expect(dto.name.en, "Didouche Station");
        // GeoJSON [lng, lat] correctly un-swapped to named fields.
        expect(dto.position.latitude, 36.75);
        expect(dto.position.longitude, 3.06);
        expect(dto.pinColor, "amber");
        expect(dto.distanceMeters, 180.5);
        expect(dto.averageRating, 4.6);
        expect(dto.reviewCount, 32);
        expect(dto.isFree, isFalse);
        expect(dto.tags, <String>["women_confirmed", "wudu"]);
      },
    );

    test("falls back to French when 'en' is absent (pre-ADR-0017 payload)", () {
      final dto = PlaceDto.fromJson(_stationJson());
      expect(dto.name.en, "Station Didouche");
    });

    test("defaults averageRating to null and tags to empty when absent", () {
      final json = _stationJson()
        ..remove("averageRating")
        ..remove("tags");
      final dto = PlaceDto.fromJson(json);
      expect(dto.averageRating, isNull);
      expect(dto.tags, isEmpty);
    });

    test(
      "defaults distanceMeters to 0 rather than throwing when absent "
      "(regression: StationDetail/ThirdPartyPlaceDetail responses never "
      "include it — Release Validation, found on a real device against "
      "the real backend)",
      () {
        final json = _stationJson(en: "x")..remove("distanceMeters");
        final dto = PlaceDto.fromJson(json);
        expect(dto.distanceMeters, 0);
      },
    );
  });

  group("PlaceDto.toEntity", () {
    test("maps placeKind and pinColor strings to Domain enums", () {
      final entity = PlaceDto.fromJson(_stationJson(en: "x")).toEntity();
      expect(entity.placeKind, PlaceKind.station);
      expect(entity.pinColor, PinColor.amber);
    });

    test("maps an unrecognized pinColor to blue rather than throwing", () {
      final json = _stationJson(en: "x");
      json["pinColor"] = "not-a-real-color";
      final entity = PlaceDto.fromJson(json).toEntity();
      expect(entity.pinColor, PinColor.blue);
    });

    test("maps third_party_place to PlaceKind.thirdPartyPlace", () {
      final json = _stationJson(en: "x");
      json["placeKind"] = "third_party_place";
      final entity = PlaceDto.fromJson(json).toEntity();
      expect(entity.placeKind, PlaceKind.thirdPartyPlace);
    });
  });
}
