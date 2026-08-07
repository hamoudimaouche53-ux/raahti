import "../entities/coordinates.dart";
import "../entities/route.dart";
import "../repositories/route_repository.dart";

/// Application-layer use case for in-app navigation's routing step: "a
/// walking route from the user's current position to a destination." A thin
/// orchestration over [RouteRepository] today, mirroring [GetNearbyPlaces]'s
/// own doc comment — the seam exists so future rules (e.g. preferring a
/// cached route when the request would be a near-duplicate) land here, not
/// in the Presentation layer or the repository implementation.
class GetRoute {
  const GetRoute(this._repository);

  final RouteRepository _repository;

  Future<NavigationRoute> call({
    required Coordinates origin,
    required Coordinates destination,
  }) {
    return _repository.getWalkingRoute(
      origin: origin,
      destination: destination,
    );
  }
}
