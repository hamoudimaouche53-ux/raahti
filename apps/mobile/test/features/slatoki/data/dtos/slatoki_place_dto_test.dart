import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/slatoki/data/dtos/slatoki_place_dto.dart";
import "package:rahati/features/slatoki/domain/entities/women_verification_level.dart";

Map<String, dynamic> _json({required String womenVerificationLevel}) =>
    <String, dynamic>{
      "id": "1",
      "placeKind": "third_party_place",
      "name": <String, dynamic>{"fr": "F", "ar": "A", "en": "E"},
      "position": <String, dynamic>{
        "type": "Point",
        "coordinates": <double>[3.06, 36.75],
      },
      "pinColor": "magenta",
      "distanceMeters": 80.0,
      "averageRating": 4.5,
      "reviewCount": 3,
      "isFree": true,
      "tags": <String>["prayer", "wudu"],
      "womenVerificationLevel": womenVerificationLevel,
    };

void main() {
  group("SlatokiPlaceDto", () {
    test("fromJson delegates the base PlaceSummary fields to PlaceDto", () {
      final dto = SlatokiPlaceDto.fromJson(
        _json(womenVerificationLevel: "generic"),
      );

      expect(dto.place.id, "1");
      expect(dto.place.name.en, "E");
      expect(dto.place.tags, ["prayer", "wudu"]);
    });

    test(
      "toEntity maps 'verified_confirmed' to WomenVerificationLevel.verifiedConfirmed",
      () {
        final entity = SlatokiPlaceDto.fromJson(
          _json(womenVerificationLevel: "verified_confirmed"),
        ).toEntity();

        expect(
          entity.womenVerificationLevel,
          WomenVerificationLevel.verifiedConfirmed,
        );
      },
    );

    test("toEntity maps 'generic' to WomenVerificationLevel.generic", () {
      final entity = SlatokiPlaceDto.fromJson(
        _json(womenVerificationLevel: "generic"),
      ).toEntity();

      expect(entity.womenVerificationLevel, WomenVerificationLevel.generic);
    });

    test("toEntity carries the underlying Place through unchanged", () {
      final entity = SlatokiPlaceDto.fromJson(
        _json(womenVerificationLevel: "generic"),
      ).toEntity();

      expect(entity.place.distanceMeters, 80.0);
      expect(entity.place.averageRating, 4.5);
    });
  });
}
