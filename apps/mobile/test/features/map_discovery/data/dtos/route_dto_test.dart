import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/data/dtos/route_dto.dart";

Map<String, dynamic> _routeJson() => <String, dynamic>{
  "polyline": r"_p~iF~ps|U_ulLnnqC_mqNvxq`@",
  "distanceMeters": 542.3,
  "durationSeconds": 411.0,
};

void main() {
  group("RouteDto.fromJson", () {
    test("parses a full Route payload (matching openapi.yaml Route)", () {
      final dto = RouteDto.fromJson(_routeJson());

      expect(dto.polyline, r"_p~iF~ps|U_ulLnnqC_mqNvxq`@");
      expect(dto.distanceMeters, 542.3);
      expect(dto.durationSeconds, 411.0);
    });

    test("coerces integer JSON numbers to double", () {
      final json = _routeJson()
        ..["distanceMeters"] = 500
        ..["durationSeconds"] = 300;
      final dto = RouteDto.fromJson(json);

      expect(dto.distanceMeters, 500.0);
      expect(dto.durationSeconds, 300.0);
    });
  });

  group("RouteDto.toEntity", () {
    test("decodes the polyline into NavigationRoute.points", () {
      final entity = RouteDto.fromJson(_routeJson()).toEntity();

      expect(entity.points, hasLength(3));
      expect(entity.points.first.latitude, closeTo(38.5, 1e-5));
      expect(entity.points.first.longitude, closeTo(-120.2, 1e-5));
    });

    test("passes distanceMeters/durationSeconds through unchanged", () {
      final entity = RouteDto.fromJson(_routeJson()).toEntity();

      expect(entity.distanceMeters, 542.3);
      expect(entity.durationSeconds, 411.0);
    });
  });
}
