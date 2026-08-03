import "../../../map_discovery/domain/entities/coordinates.dart";
import "../entities/slatoki_place.dart";

/// Domain-owned failure hierarchy (not an HTTP status/Data-layer exception),
/// scoped to this bounded context rather than reusing `map_discovery`'s
/// `PlaceRepositoryFailure` — Slatoki owns its own repository contract, per
/// the module-boundary discipline docs/architecture/module-dependency-diagram.md
/// establishes on the backend side.
sealed class SlatokiPlaceRepositoryFailure implements Exception {
  const SlatokiPlaceRepositoryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// No backend API base URL is configured for this build — expected until
/// ADR-0016's hosting decision lands and a backend is deployed.
class SlatokiApiNotConfiguredFailure extends SlatokiPlaceRepositoryFailure {
  const SlatokiApiNotConfiguredFailure()
    : super("No backend API is configured for this build.");
}

/// The API call was attempted but failed (network unreachable, non-2xx
/// response, malformed payload).
class SlatokiPlaceFetchFailure extends SlatokiPlaceRepositoryFailure {
  const SlatokiPlaceFetchFailure(super.message);
}

/// Repository port for `GET /slatoki/places` (FR-SLK-03/04/05). Implemented
/// by the Data layer (`RestSlatokiPlaceRepository`); Domain and
/// Presentation depend only on this interface.
///
/// No offline-cache fallback (unlike `map_discovery`'s `PlaceRepository`) —
/// same precedent as `PlaceDetailRepository` (Feature 6): a genuinely
/// separate concern (ADR-0008/ADR-0022) this story doesn't require.
abstract interface class SlatokiPlaceRepository {
  Future<List<SlatokiPlace>> getSlatokiPlaces({required Coordinates center});
}
