# packages/design-tokens

Shared Material Design 3 design tokens — the **machine-readable source of truth** behind [`docs/design/foundations.md`](../../docs/design/foundations.md). Consumed by `apps/web`, `apps/operator-dashboard`, and `apps/sponsor-dashboard` once a web M3 component library is selected ([Phase 2 Implementation Plan §4](../../docs/phase-2-implementation-plan.md#4-phase-2-decisions-required-not-decidable-in-phase-1)). **Not** consumed by `apps/mobile` — Flutter expresses its M3 `ColorScheme`/`TextTheme` natively in Dart, hand-mapped from these same values by convention (see [Repository Structure §2](../../docs/architecture/repository-structure.md#2-top-level-structure)).

## Files

| File | Contents | Foundations reference |
|---|---|---|
| [`color.json`](./color.json) | M3 baseline roles (light + dark) + 4 brand functional-color extensions | [§1](../../docs/design/foundations.md#1-color) |
| [`typography.json`](./typography.json) | Full M3 type scale + FR/EN/AR font-family mapping | [§2](../../docs/design/foundations.md#2-typography) |
| [`spacing.json`](./spacing.json) | 8dp-grid spacing scale | [§6](../../docs/design/foundations.md#6-spacing-8dp-grid-per-this-phases-explicit-instruction) |
| [`shape.json`](./shape.json) | Corner-radius scale | [§7](../../docs/design/foundations.md#7-shape) |
| [`elevation.json`](./elevation.json) | 6 elevation levels | [§4](../../docs/design/foundations.md#4-elevation) |
| [`motion.json`](./motion.json) | Duration + easing tokens | [§5](../../docs/design/foundations.md#5-motion) |
| [`state.json`](./state.json) | Interaction state-layer opacities | [§8](../../docs/design/foundations.md#8-interaction-states) |

## Status Note
`color.json`'s `seed` value is marked `"status": "provisional"` — see [Assumptions & Open Questions §2](../../docs/design/assumptions-and-open-questions.md#2-brand-seed-color-rah-doc-002-not-supplied). Every other file is final for Phase 2 pending the trilingual-typeface review flagged in [Assumptions §3](../../docs/design/assumptions-and-open-questions.md#3-typography).

## Governance
Token changes are versioned edits to these files, reviewed like any other design-system change (see [Design System Specification §6](../../docs/design/design-system-specification.md#6-design-system-governance-for-phase-3)). Phase 3+ implementation code must read these values, never hard-code them.
