# Phase 2 Implementation Plan

| | |
|---|---|
| **Document ID** | RAH-DOC-030-PHASE-2-PLAN |
| **Phase** | Prepared in Phase 1 — System Architecture, executed in Phase 2 — Design System |
| **Version** | 1.0 |
| **Related** | [ADR-0011](./adr/0011-material-design-3-as-design-system.md) · [Product Backlog](./backlog/product-backlog.md) · [Repository Structure](./architecture/repository-structure.md) |

## 1. Phase 2 Scope (per Master Roadmap)
"Design System, UI Kit, branding, accessibility, Figma."

## 2. Inputs Handed Off From Phase 1

| Input | Source | What it fixes for Phase 2 |
|---|---|---|
| Material Design 3 as mandatory design system | [ADR-0011](./adr/0011-material-design-3-as-design-system.md) | Component library baseline — Phase 2 builds ON M3, does not choose a different system |
| WCAG 2.2 AA accessibility target | [SRS NFR-A11Y-02](./srs/SRS.md#84-accessibility--design-system-9-new) | Concrete, testable bar for every screen/component Phase 2 produces |
| RAH-DOC-002 brand functional colors as M3 color-role extension | [ADR-0011](./adr/0011-material-design-3-as-design-system.md) | Fixes *how* brand colors integrate with M3 (extension, not replacement) — Phase 2 defines the exact tonal values |
| Light + dark theme requirement | [SRS NFR-A11Y-04](./srs/SRS.md#84-accessibility--design-system-9-new) | Every component ships in both themes, not light-only with dark deferred |
| Flutter (mobile) confirmed; web M3 library open | [ADR-0002](./adr/0002-mobile-framework-selection.md), [ADR-0011 consequences](./adr/0011-material-design-3-as-design-system.md#consequences) | Mobile components target Flutter's `material` library; **Phase 2 must select** the web M3 component approach for website + both dashboards |
| Full screen/flow inventory | [Product Backlog](./backlog/product-backlog.md) (52 stories across 10 epics), [Sequence Diagrams](./architecture/sequence-diagrams.md) | Concrete list of screens/components to design — nothing to invent, everything to trace |
| Repository location for shared tokens | [Repository Structure §2](./architecture/repository-structure.md#2-top-level-structure) | `packages/design-tokens/` already scaffolded (empty) and ready to receive Phase 2 output |

## 3. Phase 2 Deliverables (recommended)

1. **Figma library**: M3 base components + RAHATI custom color roles (green/blue/amber/magenta functional palette, per RAH-DOC-002 §4.2), typography scale (FR/AR — Arabic typeface selection is a Phase 2 decision not yet made), spacing/elevation tokens, light + dark theme variants.
2. **Design tokens export**: JSON/CSS custom properties in `packages/design-tokens/`, consumable by website/Operator/Sponsor Dashboard (once their frameworks are chosen — see §4).
3. **Component specs for custom widgets**: Qibla compass, Slatoki tent-status card, cabin-status indicator, emergency-mode entry point — each composed from M3 primitives per [ADR-0011](./adr/0011-material-design-3-as-design-system.md)'s "extend, don't replace" rule.
4. **Screen-level UX flows / high-fidelity mockups** for the full V1 backlog (EPIC-01, 02, 04, 05, 06 at minimum — see [Backlog Release Alignment](./backlog/product-backlog.md#release-alignment-per-rah-doc-005-10-and-master-roadmap)), in both FR and AR (native RTL layouts, not mirrored — per [SRS NFR-I18N-01](./srs/SRS.md)).
5. **Accessibility audit checklist**: WCAG 2.2 AA criteria mapped to each component/screen, to be re-used as a Phase 12 test-case source.
6. **Brand-to-M3 mapping documentation**: a definitive answer to exactly which M3 color roles the four RAH-DOC-002 functional colors occupy (extension slots vs. any M3 baseline role they might reasonably override) — currently only the *principle* is fixed (ADR-0011); Phase 2 fixes the *values*.

## 4. Phase 2 Decisions Required (not decidable in Phase 1)

| Decision | Why deferred to Phase 2 |
|---|---|
| M3-compliant web component library for website/Operator/Sponsor Dashboard (candidates: Material Web Components, an M3-themed React/Vue kit) | Purely a design/frontend-tooling choice, orthogonal to backend architecture — flagged in [ADR-0011 consequences](./adr/0011-material-design-3-as-design-system.md#consequences) as the one open item from that ADR |
| Arabic typeface selection (must pair with the Latin typeface used for French) | Design decision, not architectural |
| Exact tonal palette values (M3 seed color + generated tonal steps) for the brand extension colors | Requires design exploration, not just the architectural principle |

## 5. Suggested Sequencing

Per the [Phase 0 Completion Report §7](./phase-0-completion-report.md#7-recommendation-next-phase), Phase 2 can **start concurrently with Phase 1's later stages** rather than strictly after Phase 1 completes, since the Material 3 decision ([ADR-0011](./adr/0011-material-design-3-as-design-system.md)) was stable from the start of Phase 1. Recommended order within Phase 2 itself:
1. Web M3 library decision (unblocks everything web-surface-related).
2. Core token/palette definition (unblocks all component work).
3. Component library build-out.
4. Screen-level flows, starting with V1-scoped epics (backlog §3 above).
5. Accessibility audit pass across the completed set.

## 6. Exit Criteria (Phase 2 → Phase 3/4/5)

> **Status update, Phase 2 completion (2026-07-31)** — see the [Phase 2 Completion Report](./phase-2-completion-report.md) for full detail:

- [x] Design system library published and reviewed *(Markdown/JSON/interactive-prototype form rather than a native Figma file, per [Assumptions §6](./design/assumptions-and-open-questions.md#6-fidelity--delivery-method-methodological-note); review by product/engineering still pending sign-off)*.
- [x] `packages/design-tokens/` populated and consumable — 7 JSON files, see [README](../packages/design-tokens/README.md).
- [ ] Web M3 library decision recorded as a new ADR — **still open**, carried into Phase 3.
- [x] WCAG 2.2 AA checklist complete for all screens — applied system-wide via [Component Library §10](./design/component-library.md#10-accessibility-checklist-applies-to-every-component-above) and per-screen accessibility notes in every [wireframe](./design/wireframes/).
- [~] All V1 epics have a corresponding high-fidelity mockup in FR/EN/AR — **15 flagship screens** (one per UI-bearing epic) have a full FR/EN/AR, light/dark, interactive high-fidelity treatment; the remaining V1-scoped screens have a structural wireframe but not a rendered high-fidelity mockup — see [Phase 2 Completion Report §5](./phase-2-completion-report.md#5-scope-decision-wireframe-coverage-vs-high-fidelity-coverage).

## 7. Completion Status

| Item | Status |
|---|---|
| Phase 1→Phase 2 handoff inputs enumerated | ✅ Complete |
| Phase 2 deliverables and open decisions scoped | ✅ Complete |
| Exit criteria defined | ✅ Complete |
| Exit criteria executed | ✅ Complete — see status update above and [Phase 2 Completion Report](./phase-2-completion-report.md) |

**Phase 1 deliverable 10 of 10 — Implementation Plan for Phase 2: COMPLETE. Phase 2 itself: COMPLETE — see [Phase 2 Completion Report](./phase-2-completion-report.md).**
