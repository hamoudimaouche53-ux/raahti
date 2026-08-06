import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/emergency/domain/entities/emergency_facility_result.dart";
import "package:rahati/features/emergency/domain/repositories/emergency_repository.dart";
import "package:rahati/features/emergency/domain/usecases/find_nearest_emergency_facility.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";

Place _place() => const Place(
  id: "place-1",
  placeKind: PlaceKind.station,
  name: LocalizedText(
    fr: "Station Didouche",
    ar: "محطة ديدوش",
    en: "Didouche Station",
  ),
  position: Coordinates(latitude: 36.75, longitude: 3.06),
  pinColor: PinColor.green,
  distanceMeters: 180,
  averageRating: null,
  reviewCount: 0,
  isFree: true,
  tags: <String>[],
);

class _FakeEmergencyRepository implements EmergencyRepository {
  _FakeEmergencyRepository({this.result, this.failure});

  final EmergencyFacilityResult? result;
  final EmergencyRepositoryFailure? failure;
  int callCount = 0;
  Coordinates? lastPosition;

  @override
  Future<EmergencyFacilityResult?> findNearestFacility({
    required Coordinates position,
  }) async {
    callCount++;
    lastPosition = position;
    final EmergencyRepositoryFailure? f = failure;
    if (f != null) throw f;
    return result;
  }
}

void main() {
  group("FindNearestEmergencyFacility", () {
    test("delegates to the repository with the given position", () async {
      final EmergencyFacilityResult expected = EmergencyFacilityResult(
        place: _place(),
        nearestCabinId: "cabin-1",
        discountEligible: true,
        etaMinutesOnFoot: 2,
      );
      final repository = _FakeEmergencyRepository(result: expected);
      final useCase = FindNearestEmergencyFacility(repository);
      const Coordinates position = Coordinates(
        latitude: 36.75,
        longitude: 3.06,
      );

      final EmergencyFacilityResult? result = await useCase(position: position);

      expect(result, same(expected));
      expect(repository.callCount, 1);
      expect(repository.lastPosition, position);
    });

    test("returns null when the repository finds no facility (404)", () async {
      final repository = _FakeEmergencyRepository(result: null);
      final useCase = FindNearestEmergencyFacility(repository);

      final EmergencyFacilityResult? result = await useCase(
        position: const Coordinates(latitude: 0, longitude: 0),
      );

      expect(result, isNull);
    });

    test("propagates a repository failure", () async {
      final repository = _FakeEmergencyRepository(
        failure: const EmergencyApiNotConfiguredFailure(),
      );
      final useCase = FindNearestEmergencyFacility(repository);

      await expectLater(
        () => useCase(position: const Coordinates(latitude: 0, longitude: 0)),
        throwsA(isA<EmergencyApiNotConfiguredFailure>()),
      );
    });
  });
}
