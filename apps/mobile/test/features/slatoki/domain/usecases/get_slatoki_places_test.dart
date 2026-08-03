import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/slatoki/domain/entities/slatoki_place.dart";
import "package:rahati/features/slatoki/domain/entities/women_verification_level.dart";
import "package:rahati/features/slatoki/domain/repositories/slatoki_place_repository.dart";
import "package:rahati/features/slatoki/domain/usecases/get_slatoki_places.dart";

const _center = Coordinates(latitude: 36.75, longitude: 3.06);

class _FakeRepository implements SlatokiPlaceRepository {
  _FakeRepository(this._result);
  final Object _result;

  @override
  Future<List<SlatokiPlace>> getSlatokiPlaces({
    required Coordinates center,
  }) async {
    if (_result is Exception) throw _result;
    return _result as List<SlatokiPlace>;
  }
}

void main() {
  test("delegates to the repository and returns its result", () async {
    final place = SlatokiPlace(
      place: Place(
        id: "1",
        placeKind: PlaceKind.station,
        name: LocalizedText(fr: "F", ar: "A", en: "E"),
        position: _center,
        pinColor: PinColor.magenta,
        distanceMeters: 10,
        averageRating: null,
        reviewCount: 0,
        isFree: true,
        tags: const [],
      ),
      womenVerificationLevel: WomenVerificationLevel.generic,
    );
    final useCase = GetSlatokiPlaces(_FakeRepository([place]));

    final result = await useCase.call(center: _center);

    expect(result, [place]);
  });

  test("propagates a repository failure", () {
    final useCase = GetSlatokiPlaces(
      _FakeRepository(const SlatokiPlaceFetchFailure("boom")),
    );

    expect(
      () => useCase.call(center: _center),
      throwsA(isA<SlatokiPlaceFetchFailure>()),
    );
  });
}
