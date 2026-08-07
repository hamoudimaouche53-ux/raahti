import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:latlong2/latlong.dart" as latlong;
import "package:permission_handler/permission_handler.dart";

import "../../../../core/theme/shape_tokens.dart";
import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../domain/entities/coordinates.dart";
import "../../domain/entities/location_failure.dart";
import "../../domain/entities/route.dart";
import "../../domain/repositories/route_repository.dart";
import "../providers/place_providers.dart";
import "../providers/route_providers.dart";
import "../widgets/route_information_card.dart";
import "../widgets/user_position_marker.dart";

/// Everything [NavigationScreen] needs about the destination — never a full
/// [Place] (this screen has no reason to depend on `map_discovery`'s wider
/// Place-detail data, only a point and a label to show).
class NavigationScreenArgs {
  const NavigationScreenArgs({
    required this.destination,
    required this.destinationLabel,
  });

  final Coordinates destination;
  final String destinationLabel;
}

/// In-app walking navigation — replaces `launchExternalNavigation` at every
/// "Route"/"Directions" entry point (Place Detail, Emergency Mode result).
/// Full-screen, minimal chrome (`parentNavigatorKey: root`, same reasoning
/// as SCR-009/013/014/etc. — see app_router.dart's doc comment).
///
/// The map is always on screen and interactive, even while a GPS/route error
/// banner is shown on top of it (same `_StatusBanner`-over-`FlutterMap`
/// layering as `MapScreen`) — requirement 6 (UX): "The map must remain
/// interactive while routing."
class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({required this.args, super.key});

  final NavigationScreenArgs args;

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  final MapController _mapController = MapController();
  NavigationRoute? _lastFitRoute;

  @override
  void initState() {
    super.initState();

    // Regression fix: a listener registered below only reacts to *future*
    // emissions, never the value `userPositionStreamProvider` already holds
    // at the moment it starts listening. Since that provider isn't
    // `.autoDispose` and `MapScreen` keeps it warm continuously, it commonly
    // already has an `AsyncData` by the time this screen opens — without
    // this, a stationary user (no further GPS emission —
    // `DeviceLocationDataSource.watchPosition`'s `distanceFilter: 5`) would
    // never trigger the first route fetch at all.
    //
    // Deferred via `addPostFrameCallback` (same pattern this file already
    // uses for `_fitBounds`) rather than read+act synchronously here:
    // Riverpod forbids modifying a provider while the widget tree is still
    // building, which `initState` is part of — `onPositionUpdate` (via
    // `NavigationController._fetch`) writes `state`, so it can't run until
    // the current build/frame has finished.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(userPositionStreamProvider)
          .whenData(
            (coords) => ref
                .read(
                  navigationControllerProvider(
                    widget.args.destination,
                  ).notifier,
                )
                .onPositionUpdate(coords),
          );
    });

    // Covers every *subsequent* position change — no `fireImmediately`
    // needed now that the already-current value is handled above. No manual
    // disposal needed — `listenManual`'s subscription is torn down
    // automatically when this State disposes.
    ref.listenManual<AsyncValue<Coordinates>>(userPositionStreamProvider, (
      previous,
      next,
    ) {
      next.whenData(
        (coords) => ref
            .read(
              navigationControllerProvider(widget.args.destination).notifier,
            )
            .onPositionUpdate(coords),
      );
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _fitBounds(NavigationRoute route) {
    if (!mounted) return;
    final List<latlong.LatLng> points = <latlong.LatLng>[
      for (final Coordinates c in route.points)
        latlong.LatLng(c.latitude, c.longitude),
      latlong.LatLng(
        widget.args.destination.latitude,
        widget.args.destination.longitude,
      ),
    ];
    if (points.isEmpty) return;
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(RahatiSpacing.space12),
      ),
    );
  }

  String _positionErrorLabel(AppLocalizations l10n, Object? error) {
    return switch (error) {
      LocationServiceDisabledFailure() => l10n.navigationGpsDisabled,
      LocationPermissionDeniedFailure() ||
      LocationPermissionDeniedForeverFailure() =>
        l10n.navigationPermissionDenied,
      _ => l10n.navigationNetworkError,
    };
  }

  String _routeFailureLabel(AppLocalizations l10n, Object? error) {
    return switch (error) {
      RouteNotFoundFailure() => l10n.navigationNoRouteFound,
      RouteApiNotConfiguredFailure() => l10n.navigationApiNotConfigured,
      _ => l10n.navigationNetworkError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<Coordinates> livePosition = ref.watch(
      userPositionStreamProvider,
    );
    final NavigationState navState = ref.watch(
      navigationControllerProvider(widget.args.destination),
    );

    ref.listen<NavigationState>(
      navigationControllerProvider(widget.args.destination),
      (previous, next) {
        final NavigationRoute? route = next.route;
        if (route == null || identical(route, _lastFitRoute)) return;
        _lastFitRoute = route;
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds(route));
      },
    );

    final Coordinates? userCoords = livePosition.value;
    final NavigationRoute? route = navState.route;

    // GPS-disabled/permission-denied take priority — without a live
    // position there's no origin to route from at all, regardless of
    // whatever `navState.failure` last held.
    final bool showPositionError = livePosition.hasError;
    final bool showPositionLoading =
        livePosition.isLoading && !showPositionError;
    final bool showRouteLoading =
        !showPositionError &&
        !showPositionLoading &&
        route == null &&
        navState.isLoading;
    final bool showRouteFailure =
        !showPositionError &&
        !showPositionLoading &&
        route == null &&
        !navState.isLoading &&
        navState.failure != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navigationTitle)),
      body: Stack(
        children: <Widget>[
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: latlong.LatLng(
                widget.args.destination.latitude,
                widget.args.destination.longitude,
              ),
              initialZoom: 15,
              maxZoom: 18,
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                // Required by OSM's tile usage policy — see ADR-0019.
                userAgentPackageName: "com.raahti.rahati",
              ),
              // `route.points.isNotEmpty`, not just `route != null` —
              // `flutter_map`'s `PolylineLayer` asserts a non-empty points
              // list internally (`LatLngBounds.fromPoints`) when computing
              // its bounding box for culling; a degenerate route (origin and
              // destination close enough that OSRM returns an empty/minimal
              // geometry) would otherwise crash the whole screen.
              if (route != null && route.points.isNotEmpty)
                PolylineLayer(
                  polylines: <Polyline>[
                    Polyline(
                      points: <latlong.LatLng>[
                        for (final Coordinates c in route.points)
                          latlong.LatLng(c.latitude, c.longitude),
                      ],
                      strokeWidth: 5,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: <Marker>[
                  Marker(
                    point: latlong.LatLng(
                      widget.args.destination.latitude,
                      widget.args.destination.longitude,
                    ),
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.location_on,
                      color: Theme.of(context).colorScheme.error,
                      size: 36,
                    ),
                  ),
                  if (userCoords != null)
                    Marker(
                      point: latlong.LatLng(
                        userCoords.latitude,
                        userCoords.longitude,
                      ),
                      width: 26,
                      height: 26,
                      child: const UserPositionMarker(),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: RahatiSpacing.space4,
            left: RahatiSpacing.space4,
            right: RahatiSpacing.space4,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (showPositionLoading)
                    _StatusBanner(
                      key: const ValueKey("position-loading"),
                      label: l10n.mapPositionLoading,
                      showSpinner: true,
                    ),
                  if (showPositionError)
                    _StatusBanner(
                      key: const ValueKey("position-error"),
                      label: _positionErrorLabel(l10n, livePosition.error),
                      isError: true,
                      action:
                          (livePosition.error
                                  is LocationPermissionDeniedFailure ||
                              livePosition.error
                                  is LocationPermissionDeniedForeverFailure)
                          ? _SettingsAction(l10n: l10n)
                          : null,
                    ),
                  if (showRouteLoading)
                    _StatusBanner(
                      key: const ValueKey("route-loading"),
                      label: l10n.navigationLoadingRoute,
                      showSpinner: true,
                    ),
                  if (showRouteFailure)
                    _StatusBanner(
                      key: const ValueKey("route-error"),
                      label: _routeFailureLabel(l10n, navState.failure),
                      isError: true,
                    ),
                ],
              ),
            ),
          ),
          if (route != null)
            Positioned(
              left: RahatiSpacing.space4,
              right: RahatiSpacing.space4,
              bottom: RahatiSpacing.space4,
              child: SafeArea(
                top: false,
                child: RouteInformationCard(
                  route: route,
                  isRefreshing: navState.isLoading,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The Settings deep-link button shown alongside a permission-denied banner
/// — same `openAppSettings()` call as `qr_scanner_screen.dart`/
/// `emergency_result_screen.dart`'s identical fallback.
class _SettingsAction extends StatelessWidget {
  const _SettingsAction({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: openAppSettings,
      child: Text(l10n.navigationOpenSettingsButton),
    );
  }
}

/// Same shape/semantics as `map_screen.dart`'s own `_StatusBanner` (kept as
/// a separate, private copy rather than extracted into a shared widget — the
/// two have diverged slightly: this one supports an optional trailing
/// [action], `MapScreen`'s does not, and neither screen's version is used
/// outside its own file today).
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.label,
    this.isError = false,
    this.showSpinner = false,
    this.action,
    super.key,
  });

  final String label;
  final bool isError;
  final bool showSpinner;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color background = isError
        ? colorScheme.errorContainer
        : colorScheme.surfaceContainerHigh;
    final Color foreground = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onSurface;

    return Semantics(
      label: label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Card(
          margin: const EdgeInsets.only(bottom: RahatiSpacing.space2),
          color: background,
          shape: RoundedRectangleBorder(borderRadius: RahatiShape.mediumRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: RahatiSpacing.space4,
              vertical: RahatiSpacing.space3,
            ),
            child: Row(
              children: <Widget>[
                if (showSpinner)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                else if (isError)
                  Icon(Icons.error_outline, size: 18, color: foreground),
                const SizedBox(width: RahatiSpacing.space2),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: foreground),
                  ),
                ),
                ?action,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
