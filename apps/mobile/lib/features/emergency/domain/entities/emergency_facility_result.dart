import "../../../map_discovery/domain/entities/place.dart";

/// SCR-011's read model — mirrors the `EmergencyFacilityResult` schema in
/// docs/api/openapi.yaml (`GET /emergency/nearest-facility`, around line
/// 853-861) exactly: `place`, `nearestCabinId`, `discountEligible`. No
/// more — same "mirrors exactly what the OpenAPI response returns"
/// discipline as `AccessSession`'s own doc comment.
///
/// [place] reuses `map_discovery`'s [Place] entity directly rather than
/// inventing a second, narrower summary type — mirrors `SlatokiPlace`
/// wrapping [Place] (slatoki/domain/entities/slatoki_place.dart), not
/// `access_payment`'s independent-entity precedent. This was a deliberate
/// choice, verified rather than assumed:
/// - The OpenAPI `EmergencyFacilityResult.place` field is literally typed
///   `PlaceSummary` — the exact schema [Place]/`PlaceDto` already model,
///   field for field. Duplicating it here would just be a second copy of
///   the same 9 fields.
/// - `slatoki` and `profile` already import `map_discovery`'s domain layer
///   freely and extensively (`Place`, `Coordinates`, `Review`, `Favorite`,
///   `PlaceKind` — see e.g. `slatoki/domain/entities/slatoki_place.dart`) —
///   `Review`/`Favorite` themselves live in `map_discovery` for the same
///   reason, imported back up by `profile` — `map_discovery`'s domain
///   entities are an established shared/foundational layer other features
///   already depend on, not a boundary those features avoid crossing.
/// - `access_payment` is the one feature that keeps its own independent
///   `Money`/`AccessSession` types instead — but that is that feature's
///   own specific choice (its domain shapes, e.g. `AccessSession`, simply
///   have no `Place`-shaped counterpart to reuse), not a codebase-wide
///   rule. The doc comments asserting a strict directionality here are
///   also, on inspection, inconsistent: `place_detail_sheet.dart` (in
///   `map_discovery`) claims in the same paragraph both "`access_payment`
///   reads from `map_discovery`, never the reverse" *and* "this is still
///   `map_discovery` reading `access_payment`, the already-allowed
///   direction" — self-contradictory. `unlock_confirmation_screen.dart`
///   (in `access_payment`) states the actually-correct-per-the-real-
///   import-graph version: "`map_discovery` reads from `access_payment`,
///   never the reverse." Neither claims `map_discovery`'s own domain layer
///   is off-limits to other features — and the working code (`slatoki`,
///   `profile`) already shows it isn't.
/// - The backend's module-dependency-diagram.md groups `EmergencyModule`
///   with `SlatokiModule` as the two "orchestration" modules (no owned
///   domain aggregate, `application/interface only`) that read other
///   bounded contexts' data rather than modeling their own — the same
///   grouping this mobile-layer choice follows: Emergency reuses
///   `map_discovery`'s `Place`, exactly as Slatoki does.
class EmergencyFacilityResult {
  const EmergencyFacilityResult({
    required this.place,
    required this.nearestCabinId,
    required this.discountEligible,
    required this.etaMinutesOnFoot,
  });

  final Place place;

  /// `null` when the nearest accessible station has no cabin at all — per
  /// the OpenAPI schema's own `nullable: true`. Always a Station, never a
  /// third-party place: the backend's `findNearestAccessible` query scopes
  /// "accessible facility" to Station Network only (FR-EMG-02/EPIC-03
  /// implementation plan — no payment integration exists for third-party
  /// places, so the discount/unlock journey this screen leads into
  /// wouldn't apply to one anyway).
  final String? nearestCabinId;

  /// `true` only if the caller's `diabeticVerificationStatus = verified`
  /// (FR-EMG-03) — re-verified independently, server-side, at payment
  /// time (ADR-0031); this flag is an eligibility *signal* for the UI,
  /// never itself authoritative for the actual discount.
  final bool discountEligible;

  /// **Not** part of the OpenAPI response — SCR-011's wireframe shows
  /// "X min à pied" (ETA on foot) with no documented formula. A flagged
  /// client-side judgment call, computed from `place.distanceMeters` at
  /// the DTO→entity mapping boundary
  /// (`EmergencyFacilityResultDto.toEntity()`) assuming a ~5 km/h average
  /// walking speed — see that method's own doc comment for the exact
  /// formula.
  final int etaMinutesOnFoot;
}
