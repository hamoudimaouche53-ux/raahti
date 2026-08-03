import "../../domain/entities/cabin.dart";
import "../../domain/entities/coordinates.dart";
import "../../domain/entities/money.dart";
import "../../domain/entities/place.dart";
import "../../domain/entities/slatoki_tent.dart";
import "../../domain/entities/station_detail.dart";
import "../../domain/entities/third_party_place_detail.dart";
import "../../domain/repositories/place_detail_repository.dart";

/// **Explicitly-opt-in mock adapter** for [PlaceDetailRepository] — not
/// wired by default (see `AppEnv.useMockPlaceDetail`, off unless a build
/// explicitly sets `--dart-define=USE_MOCK_PLACE_DETAIL=true`). Exists
/// because US-01.2.2 (real-time cabin status) and US-01.2.3 (tariff)
/// depend on IoT/backend infrastructure that does not exist yet in this
/// conversation (Phase 4 hasn't started, ADR-0016 hosting is still open)
/// — this lets the Flutter presentation layer, domain contracts, and
/// repository interface be built and demonstrated for real now, with a
/// **single provider-level swap** (`placeDetailRepositoryProvider`) to
/// `RestPlaceDetailRepository` once a backend exists — no UI or business
/// logic changes required at that point.
///
/// **Every value here is fabricated and clearly labeled as such** — this
/// class's own name (`Mock...`), this doc comment, and the
/// `PlaceDetailSheet`'s visible "mock data" banner (shown whenever this
/// repository is active) are the three places that make this impossible
/// to mistake for live or cached data.
class MockPlaceDetailRepository implements PlaceDetailRepository {
  const MockPlaceDetailRepository();

  @override
  Future<StationDetail> getStationDetail(String stationId) async {
    // A short, artificial delay — makes the loading state visibly
    // demonstrable too, rather than resolving suspiciously instantly.
    await Future<void>.delayed(const Duration(milliseconds: 400));

    return StationDetail(
      summary: _mockSummary(stationId),
      configuration: StationConfiguration.fixed,
      status: StationOperationalStatus.active,
      cabins: [
        Cabin(
          id: "$stationId-cabin-1",
          code: "1",
          type: CabinType.women,
          occupancyStatus: CabinOccupancyStatus.free,
          isPaid: false,
          price: null,
        ),
        Cabin(
          id: "$stationId-cabin-2",
          code: "2",
          type: CabinType.men,
          occupancyStatus: CabinOccupancyStatus.occupied,
          isPaid: true,
          price: const Money(amount: "50", currency: "DZD"),
        ),
        Cabin(
          id: "$stationId-cabin-3",
          code: "3",
          type: CabinType.pmr,
          occupancyStatus: CabinOccupancyStatus.outOfService,
          isPaid: true,
          price: const Money(amount: "50", currency: "DZD"),
        ),
      ],
      // US-02.1.5 — same fabricated-but-shape-faithful discipline as the
      // cabins above; matches the wireframe's own "4 tapis" example.
      slatokiTent: const SlatokiTent(
        deploymentStatus: DeploymentStatus.deployed,
        matCapacity: 4,
        hasLighting: true,
        hasPrivacyCurtain: true,
      ),
    );
  }

  @override
  Future<ThirdPartyPlaceDetail> getThirdPartyPlaceDetail(String placeId) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    return ThirdPartyPlaceDetail(
      summary: _mockSummary(placeId),
      placeType: ThirdPartyPlaceType.mosque,
      declaredStatus: DeclaredStatus.open,
      statusSource: StatusSource.community,
    );
  }

  /// Never rendered by `PlaceDetailSheet` (it already has the real
  /// [Place] from the tapped marker) — exists only so this mock's return
  /// type stays faithful to the real API contract's shape (`allOf
  /// [PlaceSummary, ...]`), per this story's "do not invent backend
  /// behavior" instruction: the *shape* mirrors the real contract exactly,
  /// only the *values* are fabricated.
  Place _mockSummary(String id) => Place(
    id: id,
    placeKind: PlaceKind.station,
    name: const LocalizedText(fr: "(mock)", ar: "(mock)", en: "(mock)"),
    position: const Coordinates(latitude: 0, longitude: 0),
    pinColor: PinColor.amber,
    distanceMeters: 0,
    averageRating: null,
    reviewCount: 0,
    isFree: false,
    tags: const <String>[],
  );
}
