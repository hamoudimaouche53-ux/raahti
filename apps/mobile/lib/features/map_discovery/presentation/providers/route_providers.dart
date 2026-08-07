import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/constants/env.dart";
import "../../data/datasources/route_remote_data_source.dart";
import "../../data/repositories/rest_route_repository.dart";
import "../../domain/entities/coordinates.dart";
import "../../domain/entities/route.dart";
import "../../domain/repositories/route_repository.dart";
import "../../domain/usecases/get_route.dart";
import "place_providers.dart";

/// Dependency-injection wiring for in-app navigation — same one-line-per-layer
/// pattern as `place_providers.dart`. Reuses [httpClientProvider] (already
/// wraps `AuthenticatedHttpClient` when Supabase is configured) rather than
/// creating a second [http.Client].
final Provider<RouteRemoteDataSource> routeRemoteDataSourceProvider =
    Provider<RouteRemoteDataSource>(
      (ref) => RouteRemoteDataSource(
        ref.watch(httpClientProvider),
        baseUrl: AppEnv.apiBaseUrl,
      ),
    );

final Provider<RouteRepository> routeRepositoryProvider =
    Provider<RouteRepository>(
      (ref) => RestRouteRepository(ref.watch(routeRemoteDataSourceProvider)),
    );

final Provider<GetRoute> getRouteProvider = Provider<GetRoute>(
  (ref) => GetRoute(ref.watch(routeRepositoryProvider)),
);

/// [NavigationController]'s state. [route] is the **latest successful**
/// route — it is deliberately never cleared by a failed recalculation (see
/// [NavigationController._fetch]), so the map/route card keep showing the
/// last-known-good route (with a stale ETA) rather than blanking out every
/// time one background recalculation fails, e.g. a momentary network blip
/// mid-walk. [failure] is only ever set when there is *no* cached route yet
/// — once one exists, a failure is a silent, retried-on-next-movement event.
class NavigationState {
  const NavigationState({this.route, this.isLoading = true, this.failure});

  final NavigationRoute? route;
  final bool isLoading;
  final Object? failure;

  NavigationState copyWith({bool? isLoading}) {
    return NavigationState(
      route: route,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
    );
  }
}

/// Owns one active in-app navigation session, keyed by [destination] (see
/// [navigationControllerProvider]'s `.family`) — a fresh instance per
/// destination, with [destination] fixed for that instance's whole
/// lifetime. There is only ever one live [NavigationScreen] on screen at a
/// time, so in practice only one family member is ever active, but keying
/// by destination (rather than a single non-family instance with an
/// imperative `begin(destination)` reset) is what let this become
/// `.autoDispose` correctly: the family argument becomes this notifier's
/// *initial* state via [build] (Riverpod's sanctioned, synchronous
/// per-argument setup — never subject to the "don't modify a provider while
/// the widget tree is building" rule, unlike an imperative reset called
/// from `initState`, which is — see the regression this replaced,
/// `NavigationController.begin`, which crashed with exactly that Riverpod
/// assertion the first time any test actually mounted `NavigationScreen`).
///
/// `.autoDispose` — deliberately short-lived, scoped to exactly one
/// navigation session, with nothing outside `NavigationScreen` ever reading
/// it. Without it, popping the screen would leave this controller (and any
/// in-flight [_fetch]) alive for the app's entire remaining lifetime,
/// silently completing and mutating state nobody watches anymore. [_fetch]
/// checks [Ref.mounted] after every `await` for the same reason: once
/// auto-disposed mid-fetch, a stale continuation must not write to a
/// torn-down notifier.
///
/// Implements requirement 5 (Performance) end to end:
/// - **Cache the latest successful route** — [NavigationState.route] survives
///   a failed recalculation (see [_fetch]).
/// - **Avoid duplicate requests** — [onPositionUpdate] only calls [_fetch]
///   once per >20m movement; [NavigationScreen] calls it once per position
///   tick, never concurrently.
/// - **Cancel obsolete requests** — [_generation] is a monotonically
///   increasing token; a response for a superseded recalculation is
///   discarded rather than applied. `package:http` has no built-in request
///   abort, so this "discard the stale result" approach is the cancellation
///   this app can offer without adding a dependency or closing the shared
///   [httpClientProvider] client (which other in-flight requests may depend
///   on).
/// - **Refresh ETA after recalculation** — a new [NavigationRoute] (with its
///   own `distanceMeters`/`durationSeconds`) replaces the old one on every
///   successful fetch; `RouteInformationCard` recomputes the displayed
///   arrival time from the current wall-clock each rebuild, so it stays
///   accurate between recalculations too.
class NavigationController extends Notifier<NavigationState> {
  NavigationController(this.destination);

  /// FR requirement 3 — "Recalculate only when user movement exceeds 20 meters."
  static const double recalculateThresholdMeters = 20;

  final Coordinates destination;

  Coordinates? _lastRequestedOrigin;
  int _generation = 0;

  @override
  NavigationState build() => const NavigationState();

  /// Called on every live position tick ([NavigationScreen] listens to
  /// `userPositionStreamProvider`). Fetches on the first call for this
  /// session, then only once movement since the last *requested* origin
  /// exceeds [recalculateThresholdMeters].
  void onPositionUpdate(Coordinates origin) {
    final Coordinates? lastRequestedOrigin = _lastRequestedOrigin;
    if (lastRequestedOrigin != null &&
        lastRequestedOrigin.distanceMetersTo(origin) <=
            recalculateThresholdMeters) {
      return;
    }
    _fetch(origin);
  }

  Future<void> _fetch(Coordinates origin) async {
    final int generation = ++_generation;
    _lastRequestedOrigin = origin;
    state = state.copyWith(isLoading: true);

    try {
      final NavigationRoute route = await ref
          .read(getRouteProvider)
          .call(origin: origin, destination: destination);
      if (!ref.mounted || generation != _generation) return;
      state = NavigationState(route: route, isLoading: false);
    } catch (e) {
      if (!ref.mounted || generation != _generation) return;
      state = state.route != null
          ? state.copyWith(isLoading: false)
          : NavigationState(isLoading: false, failure: e);
    }
  }
}

// `NotifierProviderFamily` isn't exported from `flutter_riverpod`'s public
// API surface in this version — same reasoning as `place_detail_sheet_test.dart`'s
// `dynamic overrides` doc comment — so this is left type-inferred rather
// than explicitly annotated.
final navigationControllerProvider = NotifierProvider.autoDispose
    .family<NavigationController, NavigationState, Coordinates>(
      NavigationController.new,
    );
