import "../../domain/entities/station_detail.dart";
import "cabin_dto.dart";
import "place_dto.dart";
import "slatoki_tent_dto.dart";

/// JSON mapping for the `StationDetail` schema in docs/api/openapi.yaml —
/// `allOf: [PlaceSummary, {configuration, status, cabins, slatokiTent}]`,
/// so the wire payload is [PlaceDto]'s fields flattened alongside these
/// extras at the same object level (`GET /stations/{id}`).
class StationDetailDto {
  const StationDetailDto({
    required this.summary,
    required this.configuration,
    required this.status,
    required this.cabins,
    required this.slatokiTent,
  });

  factory StationDetailDto.fromJson(Map<String, dynamic> json) {
    return StationDetailDto(
      summary: PlaceDto.fromJson(json),
      configuration: json["configuration"] as String,
      status: json["status"] as String,
      cabins: (json["cabins"] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(CabinDto.fromJson)
          .toList(growable: false),
      slatokiTent: json["slatokiTent"] == null
          ? null
          : SlatokiTentDto.fromJson(
              json["slatokiTent"] as Map<String, dynamic>,
            ),
    );
  }

  final PlaceDto summary;
  final String configuration;
  final String status;
  final List<CabinDto> cabins;
  final SlatokiTentDto? slatokiTent;

  StationDetail toEntity() {
    return StationDetail(
      summary: summary.toEntity(),
      // Wire value is French ("fixe"), matching the API enum exactly —
      // not `StationConfiguration.fixed.name`, so this can't be a
      // `firstWhere(name ==)` lookup.
      configuration: switch (configuration) {
        "fixe" => StationConfiguration.fixed,
        "mobile" => StationConfiguration.mobile,
        "event" => StationConfiguration.event,
        _ => StationConfiguration.fixed,
      },
      status: StationOperationalStatus.values.firstWhere(
        (v) => v.name == status,
        orElse: () => StationOperationalStatus.active,
      ),
      cabins: cabins.map((c) => c.toEntity()).toList(growable: false),
      slatokiTent: slatokiTent?.toEntity(),
    );
  }
}
