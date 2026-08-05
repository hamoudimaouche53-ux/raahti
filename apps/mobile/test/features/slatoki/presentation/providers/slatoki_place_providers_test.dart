import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_providers.dart";
import "package:rahati/features/slatoki/domain/entities/prayer_facility_filter.dart";
import "package:rahati/features/slatoki/domain/entities/slatoki_place.dart";
import "package:rahati/features/slatoki/domain/entities/women_verification_level.dart";
import "package:rahati/features/slatoki/presentation/providers/slatoki_place_providers.dart";

const _center = Coordinates(latitude: 36.75, longitude: 3.06);

// PlaceKind.thirdPartyPlace — this test exercises tag-based narrowing
// (prayer_only/wudu_only), which only applies to third-party places; a
// station always matches every filter unconditionally regardless of tags
// (filter_slatoki_places.dart's own doc comment), so a station fixture
// would defeat the "narrows by filter" assertion below.
SlatokiPlace _place(String id, List<String> tags) => SlatokiPlace(
  place: Place(
    id: id,
    placeKind: PlaceKind.thirdPartyPlace,
    name: LocalizedText(fr: "F$id", ar: "A$id", en: "E$id"),
    position: _center,
    pinColor: PinColor.magenta,
    distanceMeters: 10,
    averageRating: null,
    reviewCount: 0,
    isFree: true,
    tags: tags,
  ),
  womenVerificationLevel: WomenVerificationLevel.generic,
);

void main() {
  test("prayerFacilityFilterProvider defaults to prayerOnly", () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(prayerFacilityFilterProvider),
      PrayerFacilityFilter.prayerOnly,
    );
  });

  test("set() updates the state", () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(prayerFacilityFilterProvider.notifier)
        .set(PrayerFacilityFilter.wuduOnly);

    expect(
      container.read(prayerFacilityFilterProvider),
      PrayerFacilityFilter.wuduOnly,
    );
  });

  test("filteredSlatokiPlacesProvider narrows slatokiPlacesProvider by the "
      "active filter", () async {
    final prayerPlace = _place("1", ["prayer"]);
    final wuduPlace = _place("2", ["wudu"]);
    final container = ProviderContainer(
      overrides: [
        userPositionProvider.overrideWith((ref) async => _center),
        slatokiPlacesProvider.overrideWith(
          (ref) async => [prayerPlace, wuduPlace],
        ),
      ],
    );
    addTearDown(container.dispose);

    // Let the underlying FutureProvider resolve.
    await container.read(slatokiPlacesProvider.future);

    final result = container.read(filteredSlatokiPlacesProvider);
    expect(result.value, [prayerPlace]);

    container
        .read(prayerFacilityFilterProvider.notifier)
        .set(PrayerFacilityFilter.wuduOnly);
    final updated = container.read(filteredSlatokiPlacesProvider);
    expect(updated.value, [wuduPlace]);
  });

  // filteredSlatokiPlacesProvider's error-propagation behavior (an
  // AsyncError input to whenData() stays an AsyncError) is Riverpod's own
  // guaranteed contract, not application logic — exercised end-to-end
  // instead at the widget level (slatoki_screen_test.dart's error-banner
  // case), which is the behavior that actually matters here: does the UI
  // show the right message when the fetch fails.
}
