import { TagCode } from '../domain/value-objects/tag.vo';
import { ThirdPartyPlace } from '../domain/entities/third-party-place.entity';

/** See station-network/application/pin-color.ts for the full derivation rationale (same flagged judgment call, mirrored per ADR-0029 module independence). */
export type PinColor = 'green' | 'blue' | 'amber' | 'magenta';

function deriveFromFlags(hasWomenConfirmedTag: boolean, isFree: boolean): PinColor {
  if (hasWomenConfirmedTag) {
    return 'magenta';
  }
  return isFree ? 'green' : 'blue';
}

export function deriveThirdPartyPlacePinColor(place: ThirdPartyPlace): PinColor {
  return deriveFromFlags(place.hasTag('women_confirmed'), place.isFree);
}

/** Same derivation, for the lightweight search-result projection. */
export function deriveThirdPartyPlacePinColorFromSearchResult(result: { tags: TagCode[]; isFree: boolean }): PinColor {
  return deriveFromFlags(result.tags.includes('women_confirmed'), result.isFree);
}
