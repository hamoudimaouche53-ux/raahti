import "dart:async";

import "package:geolocator/geolocator.dart";

import "../../domain/entities/coordinates.dart";
import "../../domain/entities/location_failure.dart";

/// Wraps the `geolocator` plugin (docs/adr/0019-map-rendering-and-geolocation-dependencies.md).
///
/// No repository/use-case ceremony around this one — it wraps a single
/// device sensor call with no alternate implementation to swap and no
/// persisted state, the same precedent the backend uses for modules that
/// own no state (docs/architecture/module-dependency-diagram.md §2:
/// Slatoki/Emergency skip domain+infrastructure folders for the same
/// reason).
class DeviceLocationDataSource {
  const DeviceLocationDataSource();

  /// Requests (if needed) and returns the device's current position.
  ///
  /// Throws a [LocationFailure] subtype if location services are off, or
  /// permission is denied/permanently denied — callers must handle all
  /// three distinctly per SCR-011's established fallback pattern.
  Future<Coordinates> getCurrentPosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledFailure();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationPermissionDeniedFailure();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedForeverFailure();
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return Coordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on TimeoutException {
      // A fresh high-accuracy fix can hang indefinitely on some devices —
      // confirmed live during Real Device QA (11+ min stuck on a device
      // with a working location subsystem: watchPosition's stream, used
      // for the live blue-dot marker, kept emitting fine throughout). Fall
      // back to the last cached fix rather than leaving nearbyPlacesProvider
      // (which awaits this future) — and the map's "locating…" banner —
      // stuck forever with no recovery.
      final Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown == null) rethrow;
      return Coordinates(
        latitude: lastKnown.latitude,
        longitude: lastKnown.longitude,
      );
    }
  }

  /// Continuous position updates — FR-MAP-06's "position tracking" (the
  /// thing US-01.1.6's lock/unlock actually toggles). Same permission/
  /// service checks as [getCurrentPosition], performed before the first
  /// emission so a listener sees the same [LocationFailure] subtypes as a
  /// stream error rather than a silently empty stream.
  Stream<Coordinates> watchPosition() async* {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledFailure();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationPermissionDeniedFailure();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedForeverFailure();
    }

    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).map(
      (position) => Coordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
    );
  }
}
