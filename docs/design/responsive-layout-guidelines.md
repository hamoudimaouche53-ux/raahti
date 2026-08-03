# Responsive Layout Guidelines

| | |
|---|---|
| **Document ID** | RAH-DOC-036-RESPONSIVE-LAYOUT |
| **Phase** | Phase 2 — UI/UX Design System and Product Design |
| **Version** | 1.0 |
| **Related** | [Foundations §6 — Spacing](./foundations.md#6-spacing-8dp-grid-per-this-phases-explicit-instruction) · [Component Library §5 — Navigation](./component-library.md#5-navigation) |

## 1. Window Size Classes (M3 breakpoints)

| Class | Width | RAHATI surfaces at this width |
|---|---|---|
| Compact | < 600dp | Mobile app (phones) — the primary target |
| Medium | 600–839dp | Mobile app on tablets (portrait), narrow Operator/Sponsor Dashboard windows |
| Expanded | 840–1199dp | Website, Operator/Sponsor Dashboard (typical desktop) |
| Large | 1200–1599dp | Operator/Sponsor Dashboard (wide desktop) |
| Extra-large | ≥ 1600dp | Operator Dashboard (multi-monitor/ops-center displays) |

## 2. Grid System

| Class | Columns | Margin | Gutter |
|---|---|---|---|
| Compact | 4 | 16dp (`space-4`) | 8dp (`space-2`) |
| Medium | 8 | 24dp (`space-6`) | 16dp (`space-4`) |
| Expanded+ | 12 | 24dp (`space-6`), capped content width 1040dp then auto-margins | 24dp (`space-6`) |

## 3. Navigation Adaptation

| Class | Mobile app | Dashboards / Website |
|---|---|---|
| Compact | Bottom Navigation Bar (4 destinations) | Top App Bar + drawer (hamburger) |
| Medium | Bottom Navigation Bar (unchanged — RAH-DOC-005 §2.3 fixes this structure regardless of screen size) | Navigation Rail (icons + labels, left-anchored in LTR / right-anchored in RTL) |
| Expanded+ | N/A (mobile app doesn't target this class) | Navigation Rail expands to a permanent Navigation Drawer (icons + labels + section grouping) |

**Mobile app rule**: the bottom navigation bar's 4-destination structure ([Component Library §5](./component-library.md#5-navigation)) is **never replaced** by a rail or drawer, even at the Medium class (tablet) — RAH-DOC-005 §2.3 fixes Map/Slatoki/Emergency/Profile as the app's primary structure regardless of device size.

## 4. Content Layout Patterns

| Pattern | Compact | Medium | Expanded+ |
|---|---|---|---|
| Map screen | Full-bleed map, bottom sheet overlay for place list/detail | Full-bleed map, persistent side list pane (list + map side-by-side) | Same as Medium, wider side pane (up to 4 grid columns) |
| Place Detail | Modal bottom sheet | Modal bottom sheet (capped width, centered) | Side sheet or in-pane detail (no modal) |
| Operator Dashboard fleet view | N/A (not a mobile-app screen) | Single-column stacked cards | Multi-column data table + filter side rail |
| Sponsor Dashboard stats | N/A | Stacked stat cards | Grid of stat cards (up to 4 per row) + chart panel |

## 5. Safe Areas & Platform Insets (Mobile)

- All screens respect device safe-area insets (notch, status bar, home indicator) — content never renders under system UI; the bottom navigation bar's height includes the bottom safe-area inset as additional padding, not a fixed 56dp regardless of device.
- Map screen is the one full-bleed exception (map content extends under the status bar with a scrim gradient), but all interactive controls (search bar, filter chips, recenter FAB) remain within the safe area.

## 6. RTL Responsive Rules

- Grid columns and margins are **direction-agnostic** (same values, mirrored placement) — no separate RTL grid spec needed.
- Navigation Rail/Drawer anchor to the **start edge** (left in LTR, right in RTL), not literally "left."
- Side-by-side patterns (Map + list pane, Dashboard table + filter rail) mirror as a unit: in RTL, the primary content (map, table) still reads start-to-end correctly because the entire pane arrangement flips, not just individual elements within it.

## 7. Text & Touch Target Scaling

- All type-scale tokens ([Foundations §2](./foundations.md#2-typography)) support OS-level dynamic type scaling up to 200% without layout breakage (WCAG 2.2 SC 1.4.4) — verified per screen in the [Wireframes](./wireframes/) "states" notes.
- Touch targets remain ≥48×48dp at every breakpoint; increasing text scale increases container height, never touch-target width below the minimum.

## 8. Completion Status

| Item | Status |
|---|---|
| Window size classes and grid system defined | ✅ Complete |
| Navigation adaptation per breakpoint defined | ✅ Complete |
| Content layout patterns for key screen types defined | ✅ Complete |
| Safe-area and RTL responsive rules defined | ✅ Complete |
| Text-scaling accessibility rule defined | ✅ Complete |

**Phase 2 deliverable 5 of 10 — Responsive Layout Guidelines: COMPLETE.**
