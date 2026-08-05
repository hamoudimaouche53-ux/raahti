import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/constants/env.dart";
import "../../../../core/providers/supabase_provider.dart";
import "../../data/datasources/place_detail_remote_data_source.dart";
import "../../data/datasources/review_remote_data_source.dart";
import "../../data/repositories/mock_cabin_realtime_repository.dart";
import "../../data/repositories/mock_place_detail_repository.dart";
import "../../data/repositories/mock_review_repository.dart";
import "../../data/repositories/rest_place_detail_repository.dart";
import "../../data/repositories/rest_review_repository.dart";
import "../../data/repositories/supabase_cabin_realtime_repository.dart";
import "../../domain/entities/cabin_occupancy_update.dart";
import "../../domain/entities/station_detail.dart";
import "../../domain/entities/third_party_place_detail.dart";
import "../../domain/repositories/cabin_realtime_repository.dart";
import "../../domain/repositories/place_detail_repository.dart";
import "../../domain/repositories/review_repository.dart";
import "../../domain/usecases/get_station_detail.dart";
import "../../domain/usecases/get_third_party_place_detail.dart";
import "place_providers.dart";

final Provider<PlaceDetailRemoteDataSource>
placeDetailRemoteDataSourceProvider = Provider<PlaceDetailRemoteDataSource>(
  (ref) => PlaceDetailRemoteDataSource(
    ref.watch(httpClientProvider),
    baseUrl: AppEnv.apiBaseUrl,
  ),
);

/// The single swap point between real and mock detail data (US-01.2.2/
/// US-01.2.3 — see `MockPlaceDetailRepository`'s doc comment and
/// ADR-0023). `AppEnv.useMockPlaceDetail` is `false` by default — this
/// resolves to [RestPlaceDetailRepository] unless a build explicitly opts
/// into the mock via `--dart-define=USE_MOCK_PLACE_DETAIL=true`.
final Provider<PlaceDetailRepository> placeDetailRepositoryProvider =
    Provider<PlaceDetailRepository>((ref) {
      if (AppEnv.useMockPlaceDetail) {
        return const MockPlaceDetailRepository();
      }
      return RestPlaceDetailRepository(
        ref.watch(placeDetailRemoteDataSourceProvider),
      );
    });

final Provider<GetStationDetail> getStationDetailProvider =
    Provider<GetStationDetail>(
      (ref) => GetStationDetail(ref.watch(placeDetailRepositoryProvider)),
    );

final Provider<GetThirdPartyPlaceDetail> getThirdPartyPlaceDetailProvider =
    Provider<GetThirdPartyPlaceDetail>(
      (ref) =>
          GetThirdPartyPlaceDetail(ref.watch(placeDetailRepositoryProvider)),
    );

/// Fetched lazily, keyed by station id, when a station's detail sheet
/// opens (US-01.2.2/US-01.2.3). No explicit `FutureProviderFamily<...>`
/// annotation — that type isn't exported from `flutter_riverpod`'s public
/// API surface in this version (same as `Override`, see place_screen tests).
final stationDetailProvider = FutureProvider.family<StationDetail, String>(
  (ref, stationId) => ref.watch(getStationDetailProvider).call(stationId),
);

/// Fetched lazily, keyed by place id, when a third-party place's detail
/// sheet opens (US-01.2.2's declarative-status half).
final thirdPartyPlaceDetailProvider =
    FutureProvider.family<ThirdPartyPlaceDetail, String>(
      (ref, placeId) =>
          ref.watch(getThirdPartyPlaceDetailProvider).call(placeId),
    );

/// Never emits — the fallback when neither the mock nor a real Supabase
/// project is configured (ADR-0016 still open). Realtime is a "nicer if
/// available" enhancement layer over `stationDetailProvider`'s already-
/// working static fetch, not a blocking operation, so this silently does
/// nothing rather than throwing (unlike a REST call's
/// `ApiNotConfiguredFailure`, which fits a request/response failure model
/// this stream-based feature doesn't share).
class _UnavailableCabinRealtimeRepository implements CabinRealtimeRepository {
  const _UnavailableCabinRealtimeRepository();

  @override
  Stream<CabinOccupancyUpdate> watchStationCabins(String stationId) =>
      const Stream<CabinOccupancyUpdate>.empty();
}

/// The swap point for live cabin-occupancy updates (US-04.5, FR-PAY-05 —
/// see `SupabaseCabinRealtimeRepository`'s and
/// `MockCabinRealtimeRepository`'s doc comments). Reuses
/// `AppEnv.useMockPlaceDetail` (not a separate flag — see
/// `MockCabinRealtimeRepository`'s doc comment) for the mock path, and
/// falls back to [_UnavailableCabinRealtimeRepository] when neither the
/// mock nor a real Supabase project is configured.
final Provider<CabinRealtimeRepository> cabinRealtimeRepositoryProvider =
    Provider<CabinRealtimeRepository>((ref) {
      if (AppEnv.useMockPlaceDetail) {
        return MockCabinRealtimeRepository();
      }
      if (!AppEnv.isSupabaseConfigured) {
        return const _UnavailableCabinRealtimeRepository();
      }
      return SupabaseCabinRealtimeRepository(ref.watch(supabaseClientProvider));
    });

/// Live occupancy updates for one station's cabins — watched by
/// `_StationCabins` alongside the already-fetched [stationDetailProvider]
/// to patch occupancy in place without a full re-fetch. `.autoDispose`
/// (a first in this codebase's providers) because each family instance
/// owns a real Realtime channel subscription — unlike the app's singleton
/// GPS/compass streams, a per-station channel must close once nothing is
/// watching it (i.e. once the place detail sheet closes), not stay open
/// for the app's whole lifetime.
final cabinOccupancyUpdatesProvider = StreamProvider.autoDispose
    .family<CabinOccupancyUpdate, String>(
      (ref, stationId) => ref
          .watch(cabinRealtimeRepositoryProvider)
          .watchStationCabins(stationId),
    );

final Provider<ReviewRemoteDataSource> reviewRemoteDataSourceProvider =
    Provider<ReviewRemoteDataSource>(
      (ref) => ReviewRemoteDataSource(
        ref.watch(httpClientProvider),
        baseUrl: AppEnv.apiBaseUrl,
      ),
    );

/// A single shared mock instance for the app's lifetime — submitting a
/// review must appear in a subsequent `getMyReviews` call, same reasoning
/// `MockPaymentMethodRepository`'s wiring already applies.
final Provider<MockReviewRepository> _mockReviewRepositoryProvider =
    Provider<MockReviewRepository>((ref) => MockReviewRepository());

/// The swap point for SCR-007/SCR-023's data (US-05.2). Reuses
/// `AppEnv.useMockAuth`, not `useMockPlaceDetail` — a review is
/// account-scoped (SCR-023 is "my" reviews), the same "demo a signed-in
/// account" scenario every other EPIC-05 port shares, even though this
/// port itself lives in `map_discovery` (see `Review`'s own doc comment
/// for why).
final Provider<ReviewRepository> reviewRepositoryProvider =
    Provider<ReviewRepository>((ref) {
      if (AppEnv.useMockAuth) {
        return ref.watch(_mockReviewRepositoryProvider);
      }
      return RestReviewRepository(ref.watch(reviewRemoteDataSourceProvider));
    });
