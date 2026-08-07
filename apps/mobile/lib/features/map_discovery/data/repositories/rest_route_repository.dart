import "../../domain/entities/coordinates.dart";
import "../../domain/entities/route.dart";
import "../../domain/repositories/route_repository.dart";
import "../datasources/route_remote_data_source.dart";

/// [RouteRepository] implementation backed by the RAHATI backend
/// (`RouteRemoteDataSource`) — unlike `RestPlaceRepository`, there is no
/// local-cache fallback: a walking route is only ever useful fresh (a stale
/// route from a previous position/destination pair would misdirect the
/// user), so a failed fetch surfaces as a failure rather than falling back
/// to cached data.
class RestRouteRepository implements RouteRepository {
  const RestRouteRepository(this._remote);

  final RouteRemoteDataSource _remote;

  @override
  Future<NavigationRoute> getWalkingRoute({
    required Coordinates origin,
    required Coordinates destination,
  }) async {
    final dto = await _remote.fetchWalkingRoute(
      origin: origin,
      destination: destination,
    );
    return dto.toEntity();
  }
}
