import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:latlong2/latlong.dart" as latlong;

import "../../../../core/theme/motion_tokens.dart";
import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../domain/entities/coordinates.dart";
import "../../domain/entities/location_failure.dart";
import "../../domain/entities/place.dart";
import "../../domain/entities/place_filter.dart";
import "../../domain/entities/places_snapshot.dart";
import "../../domain/repositories/place_repository.dart";
import "../../domain/usecases/filter_places.dart";
import "../clustering/map_marker_item.dart";
import "../clustering/place_clusterer.dart";
import "../providers/place_filter_provider.dart";
import "../providers/place_providers.dart";
import "../widgets/cluster_marker.dart";
import "../widgets/map_filter_chips.dart";
import "../widgets/map_search_bar.dart";
import "../widgets/place_detail_sheet.dart";
import "../widgets/place_marker.dart";
import "../widgets/recenter_fab.dart";
import "../widgets/user_position_marker.dart";

/// SCR-003 — Map (Home), covering **US-01.1.1 through US-01.1.7**
/// (docs/design/screen-inventory.md, docs/design/wireframes/mobile-map-discovery.md#scr-003):
/// user position + nearby places on launch (FR-MAP-01), color-coded/
/// clustered markers (FR-MAP-02), tap-to-detail (FR-MAP-03), debounced
/// search (FR-MAP-04, filtering the map's own markers directly rather than
/// SCR-004's separate suggestion-overlay screen — see ADR-0021), the
/// FR-MAP-05 quick-filter chip row (plus a distance chip pair — ADR-0021),
/// a lock/unlock recenter FAB with continuous position tracking and a
/// smooth, hand-rolled camera animation (US-01.1.6, FR-MAP-06 — no
/// `flutter_map` plugin was added, same ADR-0020 rationale: keep the
/// working `flutter_map`/`latlong2` pin intact), and an offline read cache
/// with a freshness indicator and automatic background retry (US-01.1.7,
/// FR-MAP-07, ADR-0008/ADR-0022 — see SCR-031).
///
/// Filtering never moves the camera: [filterPlaces] only narrows the list
/// [clusterPlaces] receives.
///
/// Hosted inside the 4-destination bottom navigation shell
/// (`RahatiNavShell`, ADR-0024) as the "Map" branch since EPIC-02
/// US-02.1.1 — this screen's own `Scaffold` renders below that shell's
/// `NavigationBar`, unchanged from its EPIC-01 implementation.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _cameraAnimController;

  /// Algiers — a reasonable initial camera framing while the device
  /// position is still resolving. Never presented to the user as *their*
  /// position (see [UserPositionMarker], only rendered once the real
  /// position resolves).
  static const latlong.LatLng _fallbackCenter = latlong.LatLng(36.7538, 3.0588);
  static const double _initialZoom = 12;
  static const double _maxZoom = 18;
  static const double _recenterZoom = 16;

  /// Tracked for [clusterPlaces] (US-01.1.2) — clustering must re-run as
  /// the user zooms, since the same pixel radius covers a different
  /// geographic area at each zoom level.
  double _currentZoom = _initialZoom;

  /// US-01.1.6 — whether the camera auto-follows [userPositionStreamProvider].
  /// A manual pan/zoom gesture unlocks it; the recenter FAB re-locks it and
  /// animates back to the current position (the same pattern as Google
  /// Maps' "my location" button).
  bool _isLocked = true;
  bool _hasCenteredOnce = false;

  @override
  void initState() {
    super.initState();
    _cameraAnimController = AnimationController(
      vsync: this,
      duration: RahatiMotionDuration.medium4,
    );
  }

  @override
  void dispose() {
    _cameraAnimController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture && _isLocked) {
      setState(() => _isLocked = false);
    }
    if (camera.zoom != _currentZoom) {
      setState(() => _currentZoom = camera.zoom);
    }
  }

  /// Hand-rolled smooth pan/zoom — `flutter_map`'s [MapController.move] is
  /// an instant jump with no animation support built in, and (per
  /// ADR-0020's precedent) no compatible clustering-adjacent plugin exists
  /// for this app's pinned `latlong2` version either, so this interpolates
  /// the camera manually via a plain [AnimationController] rather than
  /// adding a dependency for ~15 lines of tweening.
  Future<void> _animateCameraTo(
    latlong.LatLng target,
    double targetZoom,
  ) async {
    final latlong.LatLng start = _mapController.camera.center;
    final double startZoom = _mapController.camera.zoom;
    final Animation<double> curved = CurvedAnimation(
      parent: _cameraAnimController,
      curve: RahatiMotionEasing.standard,
    );
    void tick() {
      final double t = curved.value;
      _mapController.move(
        latlong.LatLng(
          start.latitude + (target.latitude - start.latitude) * t,
          start.longitude + (target.longitude - start.longitude) * t,
        ),
        startZoom + (targetZoom - startZoom) * t,
      );
    }

    curved.addListener(tick);
    await _cameraAnimController.forward(from: 0);
    curved.removeListener(tick);
  }

  void _onClusterTap(PlaceClusterItem cluster) {
    _animateCameraTo(
      latlong.LatLng(cluster.position.latitude, cluster.position.longitude),
      (_currentZoom + 2).clamp(0, _maxZoom),
    );
  }

  void _onPlaceTap(Place place) {
    // US-01.1.3 — modal bottom sheet, matching SCR-005's base layout
    // (docs/design/wireframes/mobile-map-discovery.md#scr-005).
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => PlaceDetailSheet(place: place),
    );
  }

  void _onRecenterPressed(AsyncValue<Coordinates> liveStreamPosition) {
    setState(() => _isLocked = true);
    final Coordinates? coords = liveStreamPosition.value;
    if (coords != null) {
      _animateCameraTo(
        latlong.LatLng(coords.latitude, coords.longitude),
        _recenterZoom,
      );
    } else {
      // No live fix yet (still resolving, or a prior permission/service
      // error) — re-running the provider redoes the permission/service
      // checks, so fixing Settings and tapping again genuinely retries.
      ref.invalidate(userPositionStreamProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Coordinates> position = ref.watch(userPositionProvider);
    final AsyncValue<Coordinates> livePosition = ref.watch(
      userPositionStreamProvider,
    );
    final AsyncValue<PlacesSnapshot> places = ref.watch(nearbyPlacesProvider);
    final bool isReconnecting = ref.watch(isReconnectingNearbyPlacesProvider);
    final PlaceFilter filter = ref.watch(placeFilterProvider);
    final AppLocalizations l10n = AppLocalizations.of(context);

    ref.listen<AsyncValue<Coordinates>>(userPositionStreamProvider, (
      previous,
      next,
    ) {
      final Coordinates? coords = next.value;
      if (coords == null || !_isLocked) return;
      // Deferred to after this frame — `ref.listen`'s callback runs
      // synchronously during `build()`, potentially before `FlutterMap`
      // has attached `_mapController` in this same pass (a fresh
      // `MapController` isn't attached until its `FlutterMap` completes
      // mounting), so calling `_mapController.camera` here directly can
      // throw. `_onClusterTap`/`_onRecenterPressed` don't need this — both
      // only ever run from a user gesture, strictly after a frame where
      // the map was already attached and interactive.
      final bool centerOnFirstFix = !_hasCenteredOnce;
      _hasCenteredOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _animateCameraTo(
          latlong.LatLng(coords.latitude, coords.longitude),
          centerOnFirstFix ? _recenterZoom : _currentZoom,
        );
      });
    });

    final PlacesSnapshot? snapshot = places.value;
    final List<Place> rawPlaces = snapshot?.places ?? const <Place>[];
    final bool isFromCache = snapshot?.isFromCache ?? false;
    final double referenceLatitude =
        livePosition.value?.latitude ??
        position.value?.latitude ??
        _fallbackCenter.latitude;
    // Filter first, then cluster — clustering only ever operates on the
    // subset the user actually wants to see. Neither step touches
    // `_mapController`, so filtering never moves the camera.
    final List<Place> filteredPlaces = filterPlaces(
      places: rawPlaces,
      filter: filter,
    );
    final List<MapMarkerItem> markerItems = clusterPlaces(
      places: filteredPlaces,
      zoom: _currentZoom,
      referenceLatitude: referenceLatitude,
    );
    final bool showNoResults =
        places.hasValue && filter.isActive && filteredPlaces.isEmpty;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _fallbackCenter,
              initialZoom: _initialZoom,
              maxZoom: _maxZoom,
              onPositionChanged: _onPositionChanged,
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                // Required by OSM's tile usage policy — see ADR-0019.
                userAgentPackageName: "com.raahti.rahati",
              ),
              MarkerLayer(
                markers: <Marker>[
                  if (livePosition.value case final Coordinates coords)
                    Marker(
                      point: latlong.LatLng(coords.latitude, coords.longitude),
                      width: 26,
                      height: 26,
                      child: const UserPositionMarker(),
                    ),
                  for (final MapMarkerItem item in markerItems)
                    switch (item) {
                      SinglePlaceMarkerItem(:final place) => Marker(
                        point: latlong.LatLng(
                          place.position.latitude,
                          place.position.longitude,
                        ),
                        // 48×48dp — matches PlaceMarker's own tap-target
                        // SizedBox (US-06.4 accessibility audit); the
                        // visual pin stays 32×32dp, centered inside.
                        width: 48,
                        height: 48,
                        child: _CacheDimmed(
                          isFromCache: isFromCache,
                          child: PlaceMarker(
                            place: place,
                            onTap: () => _onPlaceTap(place),
                          ),
                        ),
                      ),
                      PlaceClusterItem() => Marker(
                        point: latlong.LatLng(
                          item.position.latitude,
                          item.position.longitude,
                        ),
                        // 48×48dp — matches ClusterMarker's own tap-target
                        // SizedBox (US-06.4 accessibility audit); the
                        // visual badge stays 32–48dp (count-dependent),
                        // centered inside.
                        width: 48,
                        height: 48,
                        child: _CacheDimmed(
                          isFromCache: isFromCache,
                          child: ClusterMarker(
                            cluster: item,
                            onTap: () => _onClusterTap(item),
                          ),
                        ),
                      ),
                    },
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
                  MapSearchBar(
                    onQueryChanged: (value) => ref
                        .read(placeFilterProvider.notifier)
                        .setSearchQuery(value),
                  ),
                  const SizedBox(height: RahatiSpacing.space2),
                  const MapFilterChips(),
                  const SizedBox(height: RahatiSpacing.space2),
                  if (position.isLoading)
                    _StatusBanner.loading(
                      key: const ValueKey("position-loading"),
                      label: l10n.mapPositionLoading,
                    ),
                  if (position.hasError)
                    _StatusBanner.error(
                      key: const ValueKey("position-error"),
                      label: _positionErrorLabel(l10n, position.error),
                    ),
                  if (position.hasValue && places.hasError)
                    _StatusBanner.error(
                      key: const ValueKey("places-error"),
                      label: _placesErrorLabel(l10n, places.error),
                    ),
                  if (isFromCache && snapshot != null)
                    _StatusBanner.error(
                      key: const ValueKey("offline-cache"),
                      label: isReconnecting
                          ? l10n.mapReconnecting
                          : _offlineLabel(l10n, snapshot.lastSyncedAt),
                      showSpinner: isReconnecting,
                    ),
                  if (showNoResults)
                    _StatusBanner.loading(
                      key: const ValueKey("filter-no-results"),
                      label: l10n.mapFilterNoResults,
                      showSpinner: false,
                    ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            end: RahatiSpacing.space4,
            bottom: RahatiSpacing.space4,
            child: SafeArea(
              child: RecenterFab(
                isLocked: _isLocked,
                onPressed: () => _onRecenterPressed(livePosition),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _positionErrorLabel(AppLocalizations l10n, Object? error) {
    return switch (error) {
      LocationServiceDisabledFailure() => l10n.mapPositionErrorServiceDisabled,
      LocationPermissionDeniedFailure() ||
      LocationPermissionDeniedForeverFailure() =>
        l10n.mapPositionErrorPermissionDenied,
      _ => l10n.mapPositionErrorGeneric,
    };
  }

  String _placesErrorLabel(AppLocalizations l10n, Object? error) {
    return switch (error) {
      ApiNotConfiguredFailure() => l10n.mapPlacesErrorNotConfigured,
      _ => l10n.mapPlacesErrorGeneric,
    };
  }

  String _offlineLabel(AppLocalizations l10n, DateTime? lastSyncedAt) {
    if (lastSyncedAt == null) return l10n.mapOfflineNeverSynced;
    final int minutes = DateTime.now().difference(lastSyncedAt).inMinutes;
    return l10n.mapOffline(minutes.clamp(0, 1 << 30));
  }
}

/// SCR-031 — cached pins render at reduced opacity (85%) as a supplementary
/// (never sole) staleness signal alongside the offline banner's text.
class _CacheDimmed extends StatelessWidget {
  const _CacheDimmed({required this.isFromCache, required this.child});

  final bool isFromCache;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return isFromCache ? Opacity(opacity: 0.85, child: child) : child;
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner.loading({
    required this.label,
    this.showSpinner = true,
    super.key,
  }) : isError = false;

  const _StatusBanner.error({
    required this.label,
    this.showSpinner = false,
    super.key,
  }) : isError = true;

  final String label;
  final bool isError;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color background = isError
        ? colorScheme.errorContainer
        : colorScheme.surfaceContainerHigh;
    final Color foreground = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onSurface;

    // `liveRegion: true` (US-06.4 finding F24) — these banners appear and
    // change without user interaction (position resolving, a places fetch
    // failing, offline-cache staleness, a filter narrowing to zero
    // results), so a screen reader announces the change when it happens,
    // not only if/when the user happens to navigate to this element —
    // same discipline already established for `CabinStatusIndicator`.
    // `ExcludeSemantics` on the visible content avoids the child `Text`'s
    // own implicit label merging into (and duplicating) this explicit one.
    return Semantics(
      label: label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Card(
          margin: const EdgeInsets.only(bottom: RahatiSpacing.space2),
          color: background,
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
                else if (!isError)
                  Icon(Icons.search_off, size: 18, color: foreground)
                else
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
