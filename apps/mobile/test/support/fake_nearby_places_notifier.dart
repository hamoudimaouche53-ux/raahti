import "package:rahati/features/map_discovery/domain/entities/places_snapshot.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_providers.dart";

/// Test double for [nearbyPlacesProvider] (an `AsyncNotifierProvider`, so it
/// can't be overridden with a plain async function the way a `FutureProvider`
/// can — `overrideWith` needs a `NearbyPlacesNotifier Function()` factory).
///
/// Usage: `nearbyPlacesProvider.overrideWith(() => FakeNearbyPlacesNotifier(() async => mySnapshot))`.
class FakeNearbyPlacesNotifier extends NearbyPlacesNotifier {
  FakeNearbyPlacesNotifier(this._build);

  final Future<PlacesSnapshot> Function() _build;

  @override
  Future<PlacesSnapshot> build() => _build();
}
