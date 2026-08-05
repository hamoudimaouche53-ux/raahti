/**
 * Domain Model §4, FR-SLK-04 — "distinguish verified mosques with confirmed
 * women's sections from generic/unverified spaces" (RAH-DOC-005 §2.3). A
 * RAHETI station's Slatoki tent is always `verified_confirmed` (RAHETI-operated
 * infrastructure, not a self-declared third-party claim); a ThirdPartyPlace is
 * `verified_confirmed` only when explicitly tagged `women_confirmed`
 * (ERD Tag.code), otherwise `generic` — see slatoki-query.service.ts.
 */
export type WomenVerificationLevel = 'verified_confirmed' | 'generic';
