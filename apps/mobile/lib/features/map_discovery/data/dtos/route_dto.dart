import "../../../../core/utils/polyline_decoder.dart";
import "../../domain/entities/route.dart";

/// JSON mapping for the RAHATI backend's `Route` schema (docs/api/openapi.yaml,
/// `GET /v1/routes/walking`). The only layer allowed to know this wire format
/// — the Domain layer sees only [NavigationRoute].
class RouteDto {
  const RouteDto({
    required this.polyline,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  factory RouteDto.fromJson(Map<String, dynamic> json) {
    return RouteDto(
      polyline: json["polyline"] as String,
      distanceMeters: (json["distanceMeters"] as num).toDouble(),
      durationSeconds: (json["durationSeconds"] as num).toDouble(),
    );
  }

  final String polyline;
  final double distanceMeters;
  final double durationSeconds;

  NavigationRoute toEntity() {
    return NavigationRoute(
      points: decodePolyline(polyline),
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
    );
  }
}
