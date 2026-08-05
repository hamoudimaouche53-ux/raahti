import { CabinPricingMix, Station } from '../domain/entities/station.entity';

/**
 * Matches PlaceSummary.pinColor (openapi.yaml) — RAH-DOC-002 §4.2 functional
 * color coding (green=free WC, blue=paid WC, amber=RAHETI unit, magenta=Slatoki),
 * confirmed against the already-shipped mobile marker semantics
 * (apps/mobile/.../place_marker.dart). No document defines the *precedence*
 * when a station could plausibly match more than one category — this is a
 * flagged, documented judgment call (Facilities module, Phase 4), not a
 * specified rule: Slatoki (a distinguishing equipment feature) takes priority
 * over the free/paid categorization; a station whose cabins are a mix of free
 * and paid, or which has none yet, falls back to the generic "RAHETI unit"
 * (amber) bucket since a single free/paid boolean can't represent it.
 */
export type PinColor = 'green' | 'blue' | 'amber' | 'magenta';

function deriveFromFlags(hasSlatokiTent: boolean, cabinPricingMix: CabinPricingMix): PinColor {
  if (hasSlatokiTent) {
    return 'magenta';
  }
  switch (cabinPricingMix) {
    case 'all_free':
      return 'green';
    case 'all_paid':
      return 'blue';
    default:
      return 'amber';
  }
}

export function deriveStationPinColor(station: Station): PinColor {
  return deriveFromFlags(station.hasSlatokiTent, station.cabinPricingMix());
}

/** Same derivation, for the lightweight search-result projection (no full Station aggregate). */
export function deriveStationPinColorFromSearchResult(result: {
  hasSlatokiTent: boolean;
  cabinPricingMix: CabinPricingMix;
}): PinColor {
  return deriveFromFlags(result.hasSlatokiTent, result.cabinPricingMix);
}
