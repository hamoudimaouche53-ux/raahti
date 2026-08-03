// Traces to: US-01.2.2, US-01.2.3 (FR-PLC-02/03); US-02.1.5 (FR-SLK-05).
import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/data/dtos/station_detail_dto.dart";
import "package:rahati/features/map_discovery/domain/entities/cabin.dart";
import "package:rahati/features/map_discovery/domain/entities/slatoki_tent.dart";
import "package:rahati/features/map_discovery/domain/entities/station_detail.dart";

Map<String, dynamic> _baseJson({
  String configuration = "fixe",
  String status = "active",
  List<dynamic> cabins = const <dynamic>[],
  Map<String, dynamic>? slatokiTent,
}) => {
  "id": "s1",
  "placeKind": "station",
  "name": {"fr": "Station F", "ar": "محطة", "en": "Station E"},
  "position": {
    "type": "Point",
    "coordinates": [3.06, 36.75],
  },
  "pinColor": "amber",
  "distanceMeters": 100.0,
  "averageRating": null,
  "reviewCount": 0,
  "isFree": false,
  "tags": <String>[],
  "configuration": configuration,
  "status": status,
  "cabins": cabins,
  "slatokiTent": slatokiTent,
};

Map<String, dynamic> _slatokiTentJson({
  String deploymentStatus = "deployed",
  int matCapacity = 4,
  bool hasLighting = true,
  bool hasPrivacyCurtain = true,
}) => {
  "deploymentStatus": deploymentStatus,
  "matCapacity": matCapacity,
  "hasLighting": hasLighting,
  "hasPrivacyCurtain": hasPrivacyCurtain,
};

Map<String, dynamic> _cabinJson({
  String type = "H",
  String occupancyStatus = "free",
  bool isPaid = false,
  Map<String, dynamic>? price,
}) => {
  "id": "c1",
  "code": "1",
  "type": type,
  "occupancyStatus": occupancyStatus,
  "isPaid": isPaid,
  "price": price,
};

void main() {
  group("StationDetailDto", () {
    test("maps the French-wire 'fixe' configuration value to "
        "StationConfiguration.fixed, not a firstWhere(name==) mismatch", () {
      final entity = StationDetailDto.fromJson(
        _baseJson(configuration: "fixe"),
      ).toEntity();
      expect(entity.configuration, StationConfiguration.fixed);
    });

    test("maps 'mobile' and 'event' configurations", () {
      expect(
        StationDetailDto.fromJson(
          _baseJson(configuration: "mobile"),
        ).toEntity().configuration,
        StationConfiguration.mobile,
      );
      expect(
        StationDetailDto.fromJson(
          _baseJson(configuration: "event"),
        ).toEntity().configuration,
        StationConfiguration.event,
      );
    });

    test("maps station operational status", () {
      expect(
        StationDetailDto.fromJson(
          _baseJson(status: "maintenance"),
        ).toEntity().status,
        StationOperationalStatus.maintenance,
      );
    });

    test("maps cabin type wire codes H/F/Slatoki/PMR", () {
      final entity = StationDetailDto.fromJson(
        _baseJson(
          cabins: [
            _cabinJson(type: "H"),
            _cabinJson(type: "F"),
            _cabinJson(type: "Slatoki"),
            _cabinJson(type: "PMR"),
          ],
        ),
      ).toEntity();

      expect(entity.cabins.map((c) => c.type), [
        CabinType.men,
        CabinType.women,
        CabinType.slatoki,
        CabinType.pmr,
      ]);
    });

    test("maps cabin occupancy status and a null price for a free cabin", () {
      final entity = StationDetailDto.fromJson(
        _baseJson(cabins: [_cabinJson(occupancyStatus: "occupied")]),
      ).toEntity();

      expect(
        entity.cabins.single.occupancyStatus,
        CabinOccupancyStatus.occupied,
      );
      expect(entity.cabins.single.price, isNull);
    });

    test("maps a paid cabin's Money price", () {
      final entity = StationDetailDto.fromJson(
        _baseJson(
          cabins: [
            _cabinJson(
              isPaid: true,
              price: {"amount": "50", "currency": "DZD"},
            ),
          ],
        ),
      ).toEntity();

      final cabin = entity.cabins.single;
      expect(cabin.isPaid, isTrue);
      expect(cabin.price!.amount, "50");
      expect(cabin.price!.currency, "DZD");
    });

    test("an empty cabins array maps to an empty list, not a crash", () {
      final entity = StationDetailDto.fromJson(_baseJson()).toEntity();
      expect(entity.cabins, isEmpty);
    });

    test("a station without Slatoki equipment maps slatokiTent to null", () {
      final entity = StationDetailDto.fromJson(_baseJson()).toEntity();
      expect(entity.slatokiTent, isNull);
    });

    test("maps a deployed SlatokiTent with its capacity and amenities", () {
      final entity = StationDetailDto.fromJson(
        _baseJson(slatokiTent: _slatokiTentJson()),
      ).toEntity();

      final tent = entity.slatokiTent!;
      expect(tent.deploymentStatus, DeploymentStatus.deployed);
      expect(tent.matCapacity, 4);
      expect(tent.hasLighting, isTrue);
      expect(tent.hasPrivacyCurtain, isTrue);
    });

    test("maps a folded SlatokiTent with no amenities", () {
      final entity = StationDetailDto.fromJson(
        _baseJson(
          slatokiTent: _slatokiTentJson(
            deploymentStatus: "folded",
            matCapacity: 0,
            hasLighting: false,
            hasPrivacyCurtain: false,
          ),
        ),
      ).toEntity();

      final tent = entity.slatokiTent!;
      expect(tent.deploymentStatus, DeploymentStatus.folded);
      expect(tent.matCapacity, 0);
      expect(tent.hasLighting, isFalse);
      expect(tent.hasPrivacyCurtain, isFalse);
    });
  });
}
