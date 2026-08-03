import "../../../map_discovery/domain/entities/place.dart";
import "women_verification_level.dart";

/// The `GET /slatoki/places` read model (docs/api/openapi.yaml's
/// `SlatokiPlaceSummary` = `PlaceSummary` + `womenVerificationLevel`).
///
/// Wraps [Place] rather than duplicating its 9 fields — a direct code
/// expression of the Domain Model §4 framing that Slatoki "reads (never
/// writes) the other two contexts' data" (Station Network / Third-Party
/// Places): a RAHETI Slatoki tent and a verified mosque are still, at
/// their core, a `Station`/`ThirdPartyPlace` read model; Slatoki only adds
/// its own verification-level judgment on top.
class SlatokiPlace {
  const SlatokiPlace({
    required this.place,
    required this.womenVerificationLevel,
  });

  final Place place;
  final WomenVerificationLevel womenVerificationLevel;
}
