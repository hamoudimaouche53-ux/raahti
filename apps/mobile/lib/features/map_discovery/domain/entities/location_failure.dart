/// Failures the device-location data source can raise. Domain-owned so the
/// Presentation layer can show a specific, honest message (SCR-011's
/// "location-permission-denied fallback" pattern, reused here — see
/// docs/design/wireframes/mobile-emergency-payment.md#scr-011) rather than
/// a generic error for every case.
sealed class LocationFailure implements Exception {
  const LocationFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocationServiceDisabledFailure extends LocationFailure {
  const LocationServiceDisabledFailure()
    : super("Location services are disabled on this device.");
}

class LocationPermissionDeniedFailure extends LocationFailure {
  const LocationPermissionDeniedFailure()
    : super("Location permission was denied.");
}

class LocationPermissionDeniedForeverFailure extends LocationFailure {
  const LocationPermissionDeniedForeverFailure()
    : super(
        "Location permission was permanently denied; the user must "
        "enable it from system settings.",
      );
}
