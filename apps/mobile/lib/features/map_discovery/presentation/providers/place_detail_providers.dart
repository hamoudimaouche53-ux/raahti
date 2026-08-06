import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/constants/env.dart";
import "../../../../core/providers/supabase_provider.dart";
import "../../data/datasources/favorite_remote_data_source.dart";
import "../../data/datasources/place_detail_remote_data_source.dart";
import "../../data/datasources/review_remote_data_source.dart";
import "../../data/repositories/mock_cabin_realtime_repository.dart";
import "../../data/repositories/mock_favorite_repository.dart";
import "../../data/repositories/mock_place_detail_repository.dart";
import "../../data/repositories/mock_review_repository.dart";
import "../../data/repositories/rest_favorite_repository.dart";
import "../../data/repositories/rest_place_detail_repository.dart";
import "../../data/repositories/rest_review_repository.dart";
import "../../data/repositories/supabase_cabin_realtime_repository.dart";
import "../../domain/entities/cabin_occupancy_update.dart";
import "../../domain/entities/favorite.dart";
import "../../domain/entities/place.dart" show PlaceKind;
import "../../domain/entities/station_detail.dart";
import "../../domain/entities/third_party_place_detail.dart";
import "../../domain/repositories/cabin_realtime_repository.dart";
import "../../domain/repositories/favorite_repository.dart";
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

final Provider<FavoriteRemoteDataSource> favoriteRemoteDataSourceProvider =
    Provider<FavoriteRemoteDataSource>(
      (ref) => FavoriteRemoteDataSource(
        ref.watch(httpClientProvider),
        baseUrl: AppEnv.apiBaseUrl,
      ),
    );

/// A single shared mock instance for the app's lifetime — same reasoning
/// `_mockAuthRepositoryProvider` already applies (add/remove/toggle
/// mutate in-memory state a fresh instance per read would lose).
final Provider<MockFavoriteRepository> _mockFavoriteRepositoryProvider =
    Provider<MockFavoriteRepository>((ref) => MockFavoriteRepository());

/// The swap point for SCR-026's data (US-05.4).
final Provider<FavoriteRepository> favoriteRepositoryProvider =
    Provider<FavoriteRepository>((ref) {
      if (AppEnv.useMockAuth) {
        return ref.watch(_mockFavoriteRepositoryProvider);
      }
      return RestFavoriteRepository(
        ref.watch(favoriteRemoteDataSourceProvider),
        ref.watch(placeDetailRepositoryProvider),
      );
    });

/// The current favorite state for one place — read by
/// `_FavoriteToggleButton` (`place_detail_sheet.dart`, US-05.4) to decide
/// which heart icon to show and, if already favorited, which
/// [Favorite.id] to pass to [FavoriteRepository.removeFavorite].
class FavoriteStatus {
  const FavoriteStatus({required this.isFavorited, required this.favoriteId});

  final bool isFavorited;

  /// Non-null iff [isFavorited] — resolved from the matching [Favorite]
  /// entry, `null` otherwise.
  final String? favoriteId;
}

/// docs/api/openapi.yaml has no single-place "is this favorited"
/// endpoint — only `GET /users/me/favorites` (list) and `POST` (create) —
/// so, same as SCR-026 (favorites lists are documented there as "expected
/// to stay small"), this fetches the full list via
/// [FavoriteRepository.getFavorites] and searches it client-side rather
/// than inventing a dedicated per-place check.
///
/// Keyed by `(placeKind, placeId)`, not a bare place id — matches
/// [Favorite]'s own polymorphic-target vocabulary (that class's doc
/// comment), since a favorite isn't uniquely identified by [Place.id]
/// alone (a station and a third-party place could otherwise collide on
/// id). No explicit `FutureProviderFamily<...>` annotation, same reason
/// [stationDetailProvider] has none.
///
/// [FavoriteRepository.getFavorites] requires a `languageCode` to resolve
/// each returned [Favorite.placeName] — irrelevant here (only
/// [Favorite.id]/[Favorite.placeKind]/[Favorite.placeId] are read), so a
/// fixed `"en"` is passed rather than threading the active locale into
/// this family's key, which would otherwise force a redundant re-fetch on
/// every locale change for a value this provider never uses.
final favoriteStatusProvider =
    FutureProvider.family<
      FavoriteStatus,
      ({PlaceKind placeKind, String placeId})
    >((ref, key) async {
      final List<Favorite> favorites = await ref
          .watch(favoriteRepositoryProvider)
          .getFavorites(languageCode: "en");
      final Favorite? match = favorites
          .where(
            (favorite) =>
                favorite.placeKind == key.placeKind &&
                favorite.placeId == key.placeId,
          )
          .firstOrNull;
      return FavoriteStatus(isFavorited: match != null, favoriteId: match?.id);
    });
