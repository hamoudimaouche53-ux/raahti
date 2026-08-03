import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:http/http.dart" as http;

import "../../../../core/constants/env.dart";
import "../../data/datasources/device_location_data_source.dart";
import "../../data/datasources/place_local_data_source.dart";
import "../../data/datasources/place_remote_data_source.dart";
import "../../data/local/app_database.dart";
import "../../data/repositories/rest_place_repository.dart";
import "../../domain/entities/coordinates.dart";
import "../../domain/entities/places_snapshot.dart";
import "../../domain/repositories/place_repository.dart";
import "../../domain/usecases/get_nearby_places.dart";

/// Dependency-injection wiring for the map_discovery feature — one line per
/// layer boundary, mirroring docs/architecture/system-architecture.md §3's
/// DI-token/provider composition-root pattern on the backend.
final Provider<http.Client> httpClientProvider = Provider<http.Client>((ref) {
  final http.Client client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final Provider<PlaceRemoteDataSource> placeRemoteDataSourceProvider =
    Provider<PlaceRemoteDataSource>(
      (ref) => PlaceRemoteDataSource(
        ref.watch(httpClientProvider),
        baseUrl: AppEnv.apiBaseUrl,
      ),
    );

/// One connection for the app's lifetime — Drift manages its own
/// background isolate/executor internally (see [AppDatabase]).
final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>((ref) {
  final AppDatabase db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final Provider<PlaceLocalDataSource> placeLocalDataSourceProvider =
    Provider<PlaceLocalDataSource>(
      (ref) => PlaceLocalDataSource(ref.watch(appDatabaseProvider)),
    );

final Provider<PlaceRepository> placeRepositoryProvider =
    Provider<PlaceRepository>(
      (ref) => RestPlaceRepository(
        ref.watch(placeRemoteDataSourceProvider),
        ref.watch(placeLocalDataSourceProvider),
      ),
    );

final Provider<GetNearbyPlaces> getNearbyPlacesProvider =
    Provider<GetNearbyPlaces>(
      (ref) => GetNearbyPlaces(ref.watch(placeRepositoryProvider)),
    );

final Provider<DeviceLocationDataSource> deviceLocationDataSourceProvider =
    Provider<DeviceLocationDataSource>(
      (ref) => const DeviceLocationDataSource(),
    );

/// The device's current position, per FR-MAP-01 — a single fetch, used only
/// as the fixed center point for [nearbyPlacesProvider]'s query and the
/// original position-resolution status banner. `AsyncValue.error` carries a
/// [LocationFailure] subtype the UI matches on for a specific message.
///
/// Deliberately **not** used for the live blue-dot marker or the recenter
/// FAB (US-01.1.6) — see [userPositionStreamProvider] for that continuous
/// concern. Keeping the "where do I query nearby places from" center fixed
/// to one fetch avoids re-querying the backend on every GPS tick.
final FutureProvider<Coordinates> userPositionProvider =
    FutureProvider<Coordinates>((ref) {
      return ref.watch(deviceLocationDataSourceProvider).getCurrentPosition();
    });

/// Continuous position updates (US-01.1.6, FR-MAP-06's "position tracking")
/// — drives the live blue-dot marker, the recenter FAB's lock/unlock camera
/// follow, and its own GPS-disabled/permission-error state independent of
/// [userPositionProvider]'s one-shot fetch.
final StreamProvider<Coordinates> userPositionStreamProvider =
    StreamProvider<Coordinates>((ref) {
      return ref.watch(deviceLocationDataSourceProvider).watchPosition();
    });

/// `true` while a background retry fetch is in flight after a fallback to
/// cached data (SCR-031's "reconnecting" sub-state) — a plain flag, not
/// folded into [nearbyPlacesProvider]'s `AsyncValue`, since it's a
/// transient in-flight signal, not part of the actual place data.
class IsReconnectingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final NotifierProvider<IsReconnectingNotifier, bool>
isReconnectingNearbyPlacesProvider =
    NotifierProvider<IsReconnectingNotifier, bool>(IsReconnectingNotifier.new);

/// Nearby places centered on the resolved [userPositionProvider] value
/// (US-01.1.1), extended for offline/cache fallback (US-01.1.7, FR-MAP-07):
/// when a fetch fails but the local cache has data, [PlacesSnapshot]
/// carries it with `isFromCache: true`, and this notifier schedules a
/// background retry (visible via [isReconnectingNearbyPlacesProvider]) so
/// the map recovers automatically once connectivity returns — no manual
/// "retry" action required, matching FR-MAP-07's "graceful degradation"
/// framing (NFR-AVAIL-02).
class NearbyPlacesNotifier extends AsyncNotifier<PlacesSnapshot> {
  Timer? _retryTimer;

  /// Exposed for tests — the interval production code retries on.
  static const Duration retryInterval = Duration(seconds: 20);

  @override
  Future<PlacesSnapshot> build() async {
    ref.onDispose(() => _retryTimer?.cancel());
    final Coordinates center = await ref.watch(userPositionProvider.future);
    final PlacesSnapshot snapshot = await ref
        .watch(getNearbyPlacesProvider)
        .call(center: center);
    if (snapshot.isFromCache) {
      _scheduleRetry(center);
    }
    return snapshot;
  }

  void _scheduleRetry(Coordinates center) {
    _retryTimer?.cancel();
    _retryTimer = Timer(retryInterval, () => _retryNow(center));
  }

  Future<void> _retryNow(Coordinates center) async {
    ref.read(isReconnectingNearbyPlacesProvider.notifier).set(true);
    final AsyncValue<PlacesSnapshot> result = await AsyncValue.guard(
      () => ref.read(getNearbyPlacesProvider).call(center: center),
    );
    ref.read(isReconnectingNearbyPlacesProvider.notifier).set(false);

    result.when(
      data: (snapshot) {
        state = AsyncData<PlacesSnapshot>(snapshot);
        if (snapshot.isFromCache) _scheduleRetry(center);
      },
      error: (_, _) => _scheduleRetry(center),
      loading: () {},
    );
  }
}

final AsyncNotifierProvider<NearbyPlacesNotifier, PlacesSnapshot>
nearbyPlacesProvider =
    AsyncNotifierProvider<NearbyPlacesNotifier, PlacesSnapshot>(
      NearbyPlacesNotifier.new,
    );
