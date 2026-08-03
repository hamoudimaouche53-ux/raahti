# Interactive Prototype

| | |
|---|---|
| **Deliverable** | Phase 2 deliverables 8 & 9 of 10 — High-Fidelity UI Mockups + Interactive Prototype |
| **Related** | [Screen Inventory](./screen-inventory.md) · [Foundations](./foundations.md) · [Design Tokens](../../packages/design-tokens/README.md) |

**Published prototype**: https://claude.ai/code/artifact/e9d7d4ac-94ee-4f82-8930-4d307a744bf4

## What it covers

All **15 flagship screens** from the [Screen Inventory](./screen-inventory.md), one per Epic that has a UI surface, rendered from the actual [Design Tokens](../../packages/design-tokens/README.md) (color, typography, spacing, shape). Three independent toggles, each demonstrating a specific Phase 2 requirement:

| Toggle | Demonstrates |
|---|---|
| **Fidélité** — Wireframe / Hi-Fi | Deliverable 7 (structural wireframe) vs. deliverables 8–9 (high-fidelity), on the same markup/layout — proves the layout is fidelity-independent |
| **Thème** — Light / Dark | [SRS NFR-A11Y-04](../srs/SRS.md#84-accessibility--design-system-9-new) — both are first-class, not a light-only design with dark bolted on |
| **Langue** — FR / EN / AR | [ADR-0017](../adr/0017-trilingual-support-fr-ar-en.md) — AR triggers genuine RTL layout mirroring (see the dedicated "Map Home — AR/RTL" entry), not a mirrored LTR screenshot |

## Screens included

Map Home (+ AR/RTL variant), Place Detail Sheet, Slatoki Tab, Qibla Full-Screen, Emergency Mode Result, QR Scanner, Payment Method Selection, Unlock Confirmation, Profile Home, Diabetic Verification Submission, Web Landing, Operator Fleet Overview, Sponsor Stats Overview — 13 distinct screens, 15 renders counting the light/dark/RTL variants of the Map screen.

## Scope note

Per [Assumptions & Open Questions §6](./assumptions-and-open-questions.md#6-fidelity--delivery-method-methodological-note), this prototype's copy is fully trilingual for navigation, headlines, and primary actions; secondary content demonstrates the layout/RTL/theming mechanics rather than constituting the final content-authoring pass (a separate workstream per [ADR-0017](../adr/0017-trilingual-support-fr-ar-en.md)). Typography uses the system UI font stack, not the embedded Roboto Flex/Noto Arabic families specified in [Foundations §2.2](./foundations.md#22-font-families-assumption--see-assumptions-3), since the artifact sandbox blocks external font fetches — Phase 3 Flutter implementation uses the real font families per the design tokens.

The remaining 30 screens in the Screen Inventory have a full structural wireframe specification in [`wireframes/`](./wireframes/) but not a rendered high-fidelity mockup here — see [Assumptions §6](./assumptions-and-open-questions.md#6-fidelity--delivery-method-methodological-note) for why, and the [Phase 2 Completion Report](../phase-2-completion-report.md) for this tracked as a follow-up item.

## Completion Status
✅ Complete for the 15 flagship screens as scoped.
