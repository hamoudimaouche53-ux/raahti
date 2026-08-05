/**
 * FR-MAP-05 quick-filter chip values — see
 * modules/station-network/domain/value-objects/place-filter-type.vo.ts for the
 * full rationale. Duplicated here (not imported) because the composition
 * layer may only depend on each Facilities module's exported *QueryService
 * (ADR-0029), never their domain/ layer directly.
 */
export type PlaceFilterType = 'free_wc' | 'paid_wc' | 'rahati_unit' | 'slatoki';
