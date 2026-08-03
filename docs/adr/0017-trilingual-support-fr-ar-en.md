# ADR-0017: Trilingual Support — French, Arabic, English

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Product team |
| **Phase** | Phase 2 — UI/UX Design System and Product Design |
| **RAH-DOC-005 reference** | §2.7 (bilingual FR/AR only) — English is a new instruction, not present in RAH-DOC-005 |

## Context
RAH-DOC-005 §2.7 and the Phase 0 SRS (`FR-I18N-01…03`, `NFR-I18N-01`) specify bilingual FR/AR support with native RTL for Arabic. Phase 2's instructions explicitly add English ("Design for Arabic (RTL), French, and English"). This mirrors exactly how Material Design 3 was added in Phase 0 ([ADR-0011](./0011-material-design-3-as-design-system.md)): an explicit, user-approved instruction that extends — and does not contradict — an existing, narrower requirement.

## Decision
The platform supports **three languages**: French (FR), Arabic (AR, RTL), English (EN). This is recorded as a formal, additive extension to two Phase 0/1 baseline documents, via small marked addenda rather than any rewrite:
- [SRS §7 addendum](../srs/SRS.md#phase-2-addendum) extends `NFR-I18N-01` to cover English.
- [ERD §3.6 note](../erd/erd.md#36-user-account-src-ext) extends `user_account.preferred_language` from `enum(fr, ar)` to `enum(fr, ar, en)`.
- The bilingual `BilingualText` API schema ([openapi.yaml](../api/openapi.yaml)) becomes a trilingual `{ fr, ar, en }` object for entity display names — a Phase 3/4 API-contract update, tracked here rather than silently implied. **Resolved in Phase 3 Feature 1** (2026-07-31): `BilingualText.en` added as a required field; the mobile app's `LocalizedText` domain type (`lib/features/map_discovery/domain/entities/place.dart`) consumes exactly this trilingual shape.
- The "no machine translation in production" rule (§2.7) is assumed to extend to English content authoring (see [Assumptions §1](../design/assumptions-and-open-questions.md#1-baseline-extension-trilingual-support-frareng)) pending explicit product confirmation.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| Trilingual FR/AR/EN (chosen) | Matches this phase's explicit instruction; broadens accessibility to non-FR/AR speakers (tourists, international partners) | Triples content-authoring load versus bilingual; RTL/LTR mixed-language layout complexity increases slightly (AR is RTL, FR/EN are both LTR — no new RTL edge case, but three content variants per string) |
| Bilingual FR/AR only (RAH-DOC-005 baseline, unchanged) | Matches the original source document exactly | Would ignore this phase's explicit instruction |

## Consequences
### Positive
- No structural redesign needed: French and English share the same LTR layout logic; only Arabic requires the RTL adaptation already architected in [SRS NFR-I18N-01](../srs/SRS.md) and [Offline & Sync/UI work](../architecture/offline-sync-architecture.md).

### Negative / Trade-offs
- Content-authoring volume triples; flagged as an open question for product/content staffing (see [Assumptions §1](../design/assumptions-and-open-questions.md#1-baseline-extension-trilingual-support-frareng), echoing Risk R-15 from the Phase 0 Risk Register).
- API contract (`BilingualText` → trilingual) requires a Phase 3/4 update pass — not performed retroactively on the Phase 1 `openapi.yaml` in this phase, since Phase 1 is also a completed baseline; tracked as a Phase 3 handoff item instead.

## Related
- [ADR-0011](./0011-material-design-3-as-design-system.md), [Assumptions & Open Questions §1](../design/assumptions-and-open-questions.md#1-baseline-extension-trilingual-support-frareng), [SRS §7](../srs/SRS.md#phase-2-addendum), [ERD §3.6](../erd/erd.md#36-user-account-src-ext)
