import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/constants/env.dart";
import "../../../map_discovery/domain/entities/coordinates.dart";
import "../../../map_discovery/presentation/providers/place_providers.dart";
import "../../data/datasources/slatoki_place_remote_data_source.dart";
import "../../data/repositories/rest_slatoki_place_repository.dart";
import "../../domain/entities/prayer_facility_filter.dart";
import "../../domain/entities/slatoki_place.dart";
import "../../domain/repositories/slatoki_place_repository.dart";
import "../../domain/usecases/filter_slatoki_places.dart";
import "../../domain/usecases/get_slatoki_places.dart";

/// DI wiring, mirroring `map_discovery/presentation/providers/place_providers.dart`'s
/// composition-root pattern. Reuses [httpClientProvider] (already scoped to
/// the app's lifetime there) rather than creating a second `http.Client`.
final Provider<SlatokiPlaceRemoteDataSource>
slatokiPlaceRemoteDataSourceProvider = Provider<SlatokiPlaceRemoteDataSource>(
  (ref) => SlatokiPlaceRemoteDataSource(
    ref.watch(httpClientProvider),
    baseUrl: AppEnv.apiBaseUrl,
  ),
);

final Provider<SlatokiPlaceRepository> slatokiPlaceRepositoryProvider =
    Provider<SlatokiPlaceRepository>(
      (ref) => RestSlatokiPlaceRepository(
        ref.watch(slatokiPlaceRemoteDataSourceProvider),
      ),
    );

final Provider<GetSlatokiPlaces> getSlatokiPlacesProvider =
    Provider<GetSlatokiPlaces>(
      (ref) => GetSlatokiPlaces(ref.watch(slatokiPlaceRepositoryProvider)),
    );

/// Fetched once per resolved [userPositionProvider] value (map_discovery,
/// US-01.1.1) — the same one-shot position Map's own initial fetch uses,
/// not a second GPS request.
final FutureProvider<List<SlatokiPlace>> slatokiPlacesProvider =
    FutureProvider<List<SlatokiPlace>>((ref) async {
      final Coordinates center = await ref.watch(userPositionProvider.future);
      return ref.watch(getSlatokiPlacesProvider).call(center: center);
    });

class PrayerFacilityFilterNotifier extends Notifier<PrayerFacilityFilter> {
  @override
  PrayerFacilityFilter build() => PrayerFacilityFilter.prayerOnly;

  void set(PrayerFacilityFilter value) => state = value;
}

/// M3 Primary Tabs always have exactly one selection — defaults to the
/// first tab (`prayerOnly`), matching `TabBar`'s own default-index-0
/// convention and FR-SLK-03/the wireframe's tab ordering.
final NotifierProvider<PrayerFacilityFilterNotifier, PrayerFacilityFilter>
prayerFacilityFilterProvider =
    NotifierProvider<PrayerFacilityFilterNotifier, PrayerFacilityFilter>(
      PrayerFacilityFilterNotifier.new,
    );

/// [slatokiPlacesProvider], narrowed by the active [prayerFacilityFilterProvider]
/// — client-side (`filterSlatokiPlaces()`), so switching tabs never
/// re-fetches (ADR-0021 precedent).
final Provider<AsyncValue<List<SlatokiPlace>>> filteredSlatokiPlacesProvider =
    Provider<AsyncValue<List<SlatokiPlace>>>((ref) {
      final AsyncValue<List<SlatokiPlace>> places = ref.watch(
        slatokiPlacesProvider,
      );
      final PrayerFacilityFilter filter = ref.watch(
        prayerFacilityFilterProvider,
      );
      return places.whenData((list) => filterSlatokiPlaces(list, filter));
    });
