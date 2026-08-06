import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/emergency/data/datasources/emergency_remote_data_source.dart";
import "package:rahati/features/emergency/data/repositories/rest_emergency_repository.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";

const String _resultBody =
    '{"place":{"id":"place-1","placeKind":"station",'
    '"name":{"fr":"Station Didouche","ar":"محطة ديدوش","en":"Didouche Station"},'
    '"position":{"coordinates":[3.06,36.75]},"pinColor":"green",'
    '"distanceMeters":180.0,"averageRating":null,"reviewCount":0,'
    '"isFree":true,"tags":[]},'
    '"nearestCabinId":"cabin-1","discountEligible":true}';

void main() {
  group("RestEmergencyRepository", () {
    test("findNearestFacility delegates to the remote data source and maps "
        "the DTO to an entity", () async {
      final client = MockClient((request) async {
        // Explicit UTF-8 content-type — without it, `http.Response`'s
        // default (`latin1`, per its own doc comment) can't encode the
        // fixture's Arabic place name and throws at construction time.
        return http.Response(
          _resultBody,
          200,
          headers: <String, String>{
            "content-type": "application/json; charset=utf-8",
          },
        );
      });
      final repository = RestEmergencyRepository(
        EmergencyRemoteDataSource(client, baseUrl: "http://test.local"),
      );

      final result = await repository.findNearestFacility(
        position: const Coordinates(latitude: 36.75, longitude: 3.06),
      );

      expect(result, isNotNull);
      expect(result!.place.id, "place-1");
      expect(result.nearestCabinId, "cabin-1");
      expect(result.discountEligible, isTrue);
      expect(result.etaMinutesOnFoot, 2);
    });

    test("findNearestFacility returns null on a 404 response", () async {
      final client = MockClient(
        (request) async => http.Response("not found", 404),
      );
      final repository = RestEmergencyRepository(
        EmergencyRemoteDataSource(client, baseUrl: "http://test.local"),
      );

      final result = await repository.findNearestFacility(
        position: const Coordinates(latitude: 0, longitude: 0),
      );

      expect(result, isNull);
    });
  });
}
