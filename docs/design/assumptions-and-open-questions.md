# Phase 2 — Assumptions & Open Questions

| | |
|---|---|
| **Document ID** | RAH-DOC-032-PHASE-2-ASSUMPTIONS |
| **Phase** | Phase 2 — UI/UX Design System and Product Design |
| **Version** | 1.0 |
| **Purpose** | Kept **separate from the approved requirements**, per this phase's explicit instruction, so nothing here is mistaken for an approved decision. Every other Phase 2 document links back here instead of embedding its own assumptions inline. |

## 1. Baseline Extension: Trilingual Support (FR/AR/EN)

RAH-DOC-005 §2.7 and the Phase 0 [SRS](../srs/SRS.md) (`NFR-I18N-01`, `FR-I18N-*`) specify **bilingual FR/AR only**. This phase's instructions explicitly add **English** ("Design for Arabic (RTL), French, and English"). This is treated the same way Material Design 3 was treated in Phase 0: a **new, explicitly-approved instruction that extends the baseline**, not a silent scope change.

- Recorded formally as [ADR-0017](../adr/0017-trilingual-support-fr-ar-en.md).
- The [SRS](../srs/SRS.md) and [ERD](../erd/erd.md) each received a small, clearly marked, additive note (not a rewrite) pointing to ADR-0017 — see those documents' "Phase 2 Addendum" sections.
- **Open question**: RAH-DOC-005 §2.7 also states "no machine translation in production" for FR/AR. This phase assumes the same natively-authored-content rule extends to English content; if English is intended as a secondary/reference language with lighter content-authoring investment, that should be confirmed with product/content stakeholders before Phase 4.

## 2. Brand Seed Color (RAH-DOC-002 Not Supplied)

[ADR-0011](../adr/0011-material-design-3-as-design-system.md) (Phase 0) established that RAH-DOC-002's four **functional** colors (green/blue/amber/magenta pin coding) are preserved exactly as an M3 color-role extension. RAH-DOC-002 itself — including any **primary brand color** distinct from the four functional colors — was never supplied as an input (flagged already in [PRD Assumption A3](../prd/PRD.md#14-assumptions)).

**Assumption**: this phase selects an **indicative primary seed color** (`#00677E`, a deep teal) to generate the M3 baseline tonal palette (primary/secondary/tertiary roles), chosen for association with water/cleanliness/public infrastructure and for sufficient contrast separation from all four brand functional colors (so a "primary" button is never confusable with a "free/paid/RAHETI-unit/Slatoki" status color). **This must be confirmed against the actual RAH-DOC-002 brand guideline before Phase 2 output is treated as final** — if RAH-DOC-002 specifies a different primary brand color, only the token *values* change (see [Design Tokens](../../packages/design-tokens/README.md)); no structural rework is implied.

## 3. Typography

- **Latin (FR/EN) typeface**: **Roboto Flex** (variable font, M3's own reference family) — chosen for zero-licensing-friction and native M3/Flutter support ([ADR-0002](../adr/0002-mobile-framework-selection.md)).
- **Arabic typeface**: **Noto Naskh Arabic** for body/reading text (optimized for legibility at small sizes) paired with **Noto Kufi Arabic** for display/headline sizes (geometric, pairs visually with Roboto Flex's grotesque structure). **Assumption**, not a brand decision — RAH-DOC-002 was not supplied and may specify a different Arabic type family.
- **Open question**: final typeface pairing should be validated by a native Arabic-reading design reviewer for legibility at the smallest defined body size (see [Foundations §2](./foundations.md#2-typography)) before Phase 2 sign-off.

## 4. Iconography

**Assumption**: **Material Symbols (Rounded)** variable icon set — the standard M3-paired icon system, not specified by name in any prior document but implied by "follow Material Design 3 best practices" (this phase's instruction). Custom icons (Qibla compass needle, Slatoki tent glyph, cabin-status glyphs) are the only bespoke additions — see [Foundations §3](./foundations.md#3-iconography).

## 5. Component Library Scope

This phase's deliverable list names Buttons, Inputs, Cards, Lists, Navigation, Dialogs, Sheets "etc." — the "etc." is resolved by including every M3 component actually required by the [Screen Inventory](./screen-inventory.md) (Chips, Badges, Progress indicators, Snackbars, App/Top/Bottom bars, FAB, Segmented buttons, Switches, Radio/Checkbox, Tabs, Compass — the last being a bespoke composed component per [ADR-0011](../adr/0011-material-design-3-as-design-system.md)'s "extend, don't replace" rule). This is **scope completion per the "build a complete design system" objective**, not scope invention.

## 6. Fidelity & Delivery Method (Methodological Note)

Given this phase's tools produce Markdown/JSON/HTML rather than native Figma files:
- **Every screen** in the [Screen Inventory](./screen-inventory.md) receives a **structural wireframe specification** (regions, components used, states, accessibility notes) in [`wireframes/`](./wireframes/) — this is the deliverable-7 "wireframe" in full, for every screen.
- A curated set of **15 flagship screens**, chosen to cover every Epic at least once, additionally receives **ASCII-art wireframes** and a **high-fidelity, interactive HTML/CSS prototype** (light/dark, FR/AR-RTL/EN, wireframe-vs-hi-fi toggle) — see [`interactive-prototype.md`](./interactive-prototype.md) for the published link.
- The remaining screens' pixel-accurate high-fidelity treatment is **Phase 2 execution work for a visual design tool (Figma)**, per the Phase 1 handoff note in the [Phase 2 Implementation Plan §3](../phase-2-implementation-plan.md#3-phase-2-deliverables-recommended) — this was already flagged before this phase began, not discovered as a shortfall now. It is tracked as an explicit follow-up item in the [Phase 2 Completion Report](../phase-2-completion-report.md).
- This approach was chosen over shallow, low-detail mockups for all ~50 screens, on the judgment that a structurally complete specification plus a smaller set of genuinely production-representative high-fidelity screens is more useful to Phase 3 engineering than uniformly shallow coverage of everything.

## 7. Completion Status
This document is updated as new assumptions surface while authoring the rest of Phase 2; treat it as current as of the [Phase 2 Completion Report](../phase-2-completion-report.md)'s publish date.
