import "../entities/coordinates.dart";
import "../entities/route.dart";

/// Base type for failures the [RouteRepository] can raise. Domain-owned —
/// mirrors [PlaceRepositoryFailure]'s own split (see `place_repository.dart`)
/// between "not configured" and "attempted but failed", plus a third case
/// specific to routing: the provider was reached but found no route at all.
sealed class RouteRepositoryFailure implements Exception {
  const RouteRepositoryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// No backend API base URL is configured for this build
/// (`lib/core/constants/env.dart`) — same meaning as
/// `PlaceRepository`'s `ApiNotConfiguredFailure`, kept as a distinct type
/// here (rather than shared) since [RouteRepository] and `PlaceRepository`
/// are separate ports with no dependency between them.
class RouteApiNotConfiguredFailure extends RouteRepositoryFailure {
  const RouteApiNotConfiguredFailure()
    : super("No backend API is configured for this build.");
}

/// The backend was reached and answered, but no walkable route exists
/// between the two points (backend's `GET /v1/routes/walking` 404).
class RouteNotFoundFailure extends RouteRepositoryFailure {
  const RouteNotFoundFailure() : super("No walking route was found.");
}

/// The request was attempted but failed (network unreachable, non-2xx
/// response, malformed payload, or the backend's upstream routing provider
/// being unavailable — its 502).
class RouteFetchFailure extends RouteRepositoryFailure {
  const RouteFetchFailure(super.message);
}

/// Repository port for in-app walking navigation (replaces
/// `launchExternalNavigation` — every "Route"/"Directions" entry point).
/// Implemented by the Data layer (`RestRouteRepository`); the Domain and
/// Presentation layers depend only on this interface, per the
/// dependency-inversion rule in docs/architecture/system-architecture.md §3.
abstract interface class RouteRepository {
  Future<NavigationRoute> getWalkingRoute({
    required Coordinates origin,
    required Coordinates destination,
  });
}
