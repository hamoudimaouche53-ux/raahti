# Design System Specification

| | |
|---|---|
| **Document ID** | RAH-DOC-033-DESIGN-SYSTEM-SPEC |
| **Phase** | Phase 2 — UI/UX Design System and Product Design |
| **Version** | 1.0 |
| **Status** | Draft for Review |
| **Date** | 2026-07-31 |
| **Baseline** | [RAH-DOC-005](../../RAH-DOC-005-specification-plateforme-digitale.md) + [Phase 0](../phase-0-completion-report.md) + [Phase 1](../phase-1-completion-report.md) documentation (immutable) |
| **Related** | [Foundations](./foundations.md) · [Component Library](./component-library.md) · [Design Tokens](../../packages/design-tokens/README.md) · [Responsive Layout Guidelines](./responsive-layout-guidelines.md) · [User Flows](./user-flows.md) · [Screen Inventory](./screen-inventory.md) · [Wireframes](./wireframes/) · [Assumptions](./assumptions-and-open-questions.md) |

> **Baseline discipline**: exactly as in Phase 0/1, this document and everything under `docs/design/` extends the immutable baseline rather than altering it. The one true baseline extension this phase makes — trilingual FR/AR/EN support — is recorded as [ADR-0017](../adr/0017-trilingual-support-fr-ar-en.md), not silently folded in. All other design decisions (brand seed color, typeface pairing, icon set) that are not fixed by any prior document are **assumptions**, kept in the separate [Assumptions & Open Questions](./assumptions-and-open-questions.md) document per this phase's explicit instruction.

## 1. Purpose

Define RAHATI's design system — the single, reusable source for every visual and interaction decision across the mobile app, website, Operator Dashboard, and Sponsor Dashboard — so that Phase 3 (Flutter implementation) and the future web-surface implementation phases (6–8) build against a fixed, traceable specification rather than inventing UI decisions ad hoc.

## 2. Governing Principles

| Principle | Statement | Source |
|---|---|---|
| Material Design 3 as the official system | Every screen, on every surface, is built from M3 components, color roles, typography, spacing, elevation, and motion. | [ADR-0011](../adr/0011-material-design-3-as-design-system.md) (Phase 0) |
| Accessibility is a hard requirement, not an aspiration | WCAG 2.2 Level AA on every screen — contrast, touch targets, screen-reader labeling, focus order. | [SRS NFR-A11Y-02](../srs/SRS.md#84-accessibility--design-system-9-new) |
| Light and dark are both first-class | No screen ships light-only; dark theme is derived from the same token set, not hand-tuned separately. | [SRS NFR-A11Y-04](../srs/SRS.md#84-accessibility--design-system-9-new) |
| 8dp spacing grid | All spacing, padding, and sizing values are multiples of 4dp, with 8dp as the base rhythm. | This phase's explicit instruction — see [Foundations §6](./foundations.md#6-spacing) |
| Brand identity preserved inside M3, not beside it | RAH-DOC-002's four functional pin colors (green/blue/amber/magenta) are M3 color-role extensions; no bespoke non-M3 visual language is introduced anywhere else. | [ADR-0011](../adr/0011-material-design-3-as-design-system.md) |
| Trilingual, RTL-correct | Every screen is designed simultaneously for FR (LTR), EN (LTR), and AR (RTL) — RTL is a layout-direction property of the design, not a separate design. | [ADR-0017](../adr/0017-trilingual-support-fr-ar-en.md) |
| Custom components extend, never replace, M3 | The Qibla compass, Slatoki tent-status card, and cabin-status indicator are the only bespoke components in the system, and each is built by composing M3 primitives (Card, Icon, Badge, ProgressIndicator). | [SRS NFR-A11Y-05](../srs/SRS.md#84-accessibility--design-system-9-new) |
| Full traceability | Every screen references its Epic/Feature/User Story; every component's use is traceable to a screen. | This phase's explicit instruction — see [Screen Inventory](./screen-inventory.md) |

## 3. Document Map

```mermaid
graph TD
    DSS[Design System Specification\n(this document)]
    F[Foundations\ncolor · type · icon · elevation · motion · spacing]
    DT[Design Tokens\nJSON, packages/design-tokens/]
    CL[Component Library\nspecification]
    RLG[Responsive Layout\nGuidelines]
    UF[User Flows]
    SI[Screen Inventory\nEpic → Story → Screen]
    WF[Wireframes\nper screen]
    IP[Interactive Prototype\nflagship screens]
    A[Assumptions &\nOpen Questions]

    DSS --> F
    DSS --> RLG
    DSS --> UF
    DSS --> SI
    F --> DT
    CL --> DT
    F --> CL
    SI --> WF
    SI --> IP
    UF --> SI
    DSS -.references.-> A
    F -.references.-> A
    CL -.references.-> A
```

## 4. Scope

Covers all four client surfaces from [Architecture Overview §1](../architecture/architecture-overview.md#1-vue-densemble-de-la-plateforme): Mobile Application (Flutter/M3-native), Web Platform, Operator Dashboard, Sponsor Dashboard. Mobile is the reference implementation (M3's most mature target per [ADR-0002](../adr/0002-mobile-framework-selection.md)); the three web surfaces consume the same [Design Tokens](../../packages/design-tokens/README.md) once a web M3 component library is selected ([Phase 2 Implementation Plan §4](../phase-2-implementation-plan.md#4-phase-2-decisions-required-not-decidable-in-phase-1) — still an open item, see [Assumptions](./assumptions-and-open-questions.md)).

## 5. Traceability Model

```
Epic (backlog) → Feature → User Story (US-nn.n.n) → Screen (SCR-nnn) → Wireframe + Component list
```
Enforced in the [Screen Inventory](./screen-inventory.md), which is the single table every other Phase 2 document (flows, wireframes, prototype) keys off of. No screen exists in this design system without at least one User Story justifying it; no User Story with a UI-facing requirement is missing a screen.

## 6. Design System Governance (for Phase 3+)

- Any new component or token value change is proposed against this document and [Foundations](./foundations.md), not invented inline during Flutter implementation.
- Any deviation from an M3 baseline component (beyond the three approved bespoke components in §2) requires a new ADR, mirroring how architecture decisions were governed in Phase 1.
- Token changes ([Design Tokens](../../packages/design-tokens/README.md)) are versioned; Flutter theme code (Phase 3) consumes token *values*, never hard-codes them, so a brand-color correction (see [Assumptions §2](./assumptions-and-open-questions.md#2-brand-seed-color-rah-doc-002-not-supplied)) is a token-file change, not a code change across dozens of widgets.

## 7. Completion Status

| Item | Status |
|---|---|
| Governing principles fixed | ✅ Complete |
| Document map and traceability model defined | ✅ Complete |
| Governance process for Phase 3+ defined | ✅ Complete |

**Phase 2 deliverable 1 of 10 — Design System Specification: COMPLETE.**
