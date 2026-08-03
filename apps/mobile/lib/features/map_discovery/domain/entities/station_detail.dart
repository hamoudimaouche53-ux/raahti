import "cabin.dart";
import "place.dart";
import "slatoki_tent.dart";

/// Mirrors `StationDetail.configuration` in docs/api/openapi.yaml.
enum StationConfiguration { fixed, mobile, event }

/// Mirrors `StationDetail.status`.
enum StationOperationalStatus { active, inactive, maintenance }

/// The full RAHETI station detail (US-01.2.2, US-01.2.3 — FR-PLC-02/03;
/// `slatokiTent` added by US-02.1.5, FR-SLK-05), fetched lazily from
/// `GET /stations/{id}` once a place's detail sheet opens —
/// [Place]/`PlaceSummary` (the map/list read model) never carries this.
class StationDetail {
  const StationDetail({
    required this.summary,
    required this.configuration,
    required this.status,
    required this.cabins,
    required this.slatokiTent,
  });

  final Place summary;
  final StationConfiguration configuration;
  final StationOperationalStatus status;
  final List<Cabin> cabins;

  /// `null` for a station that doesn't carry Slatoki equipment.
  final SlatokiTent? slatokiTent;
}
