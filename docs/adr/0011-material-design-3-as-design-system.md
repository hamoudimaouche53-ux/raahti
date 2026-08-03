# ADR-0011: Material Design 3 (Material You) as the Official Design System

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Product team |
| **RAH-DOC-005 reference** | §9 (accessibility, generic) — Material 3 itself is a new instruction, not present in RAH-DOC-005 |

## Context
RAH-DOC-005 §9 requires accessibility "conforme aux bonnes pratiques mobiles usuelles" without naming a concrete design system or a specific accessibility standard. The product team has since instructed that **Material Design 3 (Material You)** be adopted as the official design system for the entire application (mobile, web, both dashboards), with **WCAG 2.2 AA** as the explicit accessibility target, light/dark theming, and a rule that custom components must extend rather than replace M3 primitives.

Separately, RAH-DOC-002 (Brand Identity Guidelines, §4.2, referenced by RAH-DOC-005 §2.1) defines a **functional color code** that is load-bearing product semantics, not decoration: green = free WC, blue = paid WC, amber = RAHETI mobile unit, magenta = Slatoki. This predates the Material 3 instruction and must be preserved exactly (ADR-0001's non-reinterpretation rule).

## Decision
Adopt **Material Design 3** as the design system for every surface: M3 components, the M3 color system (tonal palettes, dynamic color where supported), typography scale, spacing, elevation, and motion. Accessibility target is **WCAG 2.2 AA**, both light and dark themes are supported. The RAH-DOC-002 functional color code is implemented as a **custom M3 color-role extension**: the four brand functional colors (green/blue/amber/magenta) are defined as additional semantic color roles layered on top of the M3 baseline scheme (M3's extended-color-role mechanism), so they remain visually and functionally exact per RAH-DOC-002 while every other surface (buttons, app bars, cards, dialogs) follows standard M3 roles. Any custom widget (Qibla compass, Slatoki tent-status card, cabin-status indicator) is built by composing M3 primitives (Card, Chip, Icon, etc.), never as a one-off bespoke component.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| Material Design 3 (chosen) | First-party Flutter support ([ADR-0002](./0002-mobile-framework-selection.md)); mature accessibility tooling; consistent cross-surface language | Requires deliberate extension mechanism to preserve RAH-DOC-002's brand colors without diluting M3 |
| Fully custom design system | Maximum brand expression | Expensive to build/maintain to production-grade accessibility; contradicts the explicit Material 3 instruction |
| Material 3 replacing brand colors with M3 defaults | Simplest implementation | Would violate RAH-DOC-005 §2.1 / RAH-DOC-002 §4.2's functional color coding — explicitly disallowed by ADR-0001 |

## Consequences
### Positive
- Concretizes RAH-DOC-005 §9's generic accessibility requirement into a testable standard (WCAG 2.2 AA).
- Full design-system deliverables (UI kit, Figma library, design tokens) in Phase 2 have a fixed foundation to build against, reducing Phase 2 rework risk.
- Brand functional colors (RAH-DOC-002 §4.2) are preserved exactly, satisfying ADR-0001.

### Negative / Trade-offs
- Operator and Sponsor dashboards (web) will need an M3-equivalent web component library (e.g. Material Web Components or an M3-compliant React/Vue kit), which is not yet selected — Phase 1/2 item.

## Related
- [PRD §11.4](../prd/PRD.md#114-design-system--material-design-3-new-constraint), [SRS NFR-A11Y-02…05](../srs/SRS.md#84-accessibility--design-system-9-new), [ADR-0002](./0002-mobile-framework-selection.md)
