import "../entities/coordinates.dart";
import "../entities/places_snapshot.dart";

/// Base type for failures the [PlaceRepository] can raise. Domain-owned
/// (not an HTTP status code or a Data-layer exception type) so the
/// Presentation layer never needs to know how the failure was transported.
sealed class PlaceRepositoryFailure implements Exception {
  const PlaceRepositoryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// No backend API base URL is configured for this build
/// (`lib/core/constants/env.dart`) — expected in this environment until a
/// hosting provider is selected (ADR-0016) and a backend is deployed
/// (Phase 4, not yet started in this conversation). Distinct from
/// [PlaceFetchFailure] so the UI can show a specific "not configured"
/// message rather than a generic network-error message.
class ApiNotConfiguredFailure extends PlaceRepositoryFailure {
  const ApiNotConfiguredFailure()
    : super("No backend API is configured for this build.");
}

/// The API call was attempted but failed (network unreachable, non-2xx
/// response, malformed payload).
class PlaceFetchFailure extends PlaceRepositoryFailure {
  const PlaceFetchFailure(super.message);
}

/// Repository port for nearby-place discovery (FR-MAP-01). Implemented by
/// the Data layer (`RestPlaceRepository`); the Domain and Presentation
/// layers depend only on this interface, per the dependency-inversion rule
/// in docs/architecture/system-architecture.md §3.
abstract interface class PlaceRepository {
  /// Returns places within [radiusMeters] of [center], ordered by distance
  /// (server-side, per `GET /places/nearby` — docs/api/openapi.yaml).
  ///
  /// On a remote failure, implementations fall back to the local cache
  /// (ADR-0008/ADR-0022) and return it with `isFromCache: true` rather than
  /// throwing — FR-MAP-07 requires showing the last cached data, not an
  /// error screen, when connectivity is lost. Only throws a
  /// [PlaceRepositoryFailure] when the remote fetch fails **and** no cache
  /// exists yet (nothing usable to show at all).
  Future<PlacesSnapshot> getNearbyPlaces({
    required Coordinates center,
    double radiusMeters = 2000,
  });
}
