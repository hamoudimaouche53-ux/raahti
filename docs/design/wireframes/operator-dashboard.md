# Wireframes — Operator Dashboard

| | |
|---|---|
| **Group** | Operator Dashboard (EPIC-08) |
| **Related** | [Screen Inventory](../screen-inventory.md) · [User Flows §8](../user-flows.md#8-operator-dashboard-epic-08) · [Security Architecture §1](../../architecture/security-architecture.md#1-authentication-authn) (MFA requirement) |

> All Operator Dashboard screens are specified at the **Expanded/Large** breakpoint (primary target — field/ops staff typically use tablet or desktop, per [Responsive Layout Guidelines §1](../responsive-layout-guidelines.md#1-window-size-classes-m3-breakpoints)); Navigation Rail per that guideline's adaptation table is assumed throughout, not repeated per screen.

---

## SCR-037 Fleet Overview — **FLAGSHIP**
**Epic/Stories**: US-08.1.
**Layout regions**: Navigation Rail (start edge: Fleet, Alertes, Maintenance, Historique, Rôles) → main content: filter/search bar (by site/status) → responsive data-grid of Station cards (battery %, water level, per-cabin Cabin-Status Indicator row, active-alert count badge) → summary stat row at top (total stations, stations with active alerts, stations offline).
**Components**: Navigation Rail, Card (station status), Cabin-Status Indicator (bespoke, reused from mobile spec), Badge, Chip (filters).
**States**: all-healthy, alerts-present (affected station cards visually flagged via a leading `error`/`errorContainer` accent bar, not full-card red fill — keeps the grid scannable), loading (skeleton cards), site-scoped-empty (operator's `site_scope` has no stations — rare, but a defined empty state per RLS-scoped access, [Security Architecture §2](../../architecture/security-architecture.md#2-authorization-authz)).
**Accessibility**: data-grid is navigable via keyboard (tab/arrow) and exposes a table-equivalent screen-reader structure, not a purely visual card grid with no semantic structure.
**RTL**: Navigation Rail anchors to start edge (right in AR); data-grid column order mirrors.

```
ASCII wireframe (flagship, expanded breakpoint):

┌───┬─────────────────────────────────────────┐
│ ▤ │ Flotte    [Recherche] [Filtre: Site ▾]    │
│ Flotte │ Total: 42  Alertes: 3  Hors ligne: 1  │
│ Alertes│ ┌──────────┐ ┌──────────┐ ┌──────────┐│
│ Maint. │ │Station 01 │ │Station 02 │ │Station 03 ││
│ Hist.  │ │🔋85% 💧60%│ │🔋40% 💧20%│ │🔋90% 💧80%││
│ Rôles  │ │●Libre ●Occ│ │▮ 2 alertes│ │●Libre ●Lib││
│        │ └──────────┘ └──────────┘ └──────────┘│
└───┴─────────────────────────────────────────┘
```

## SCR-038 Alert Queue
**Epic/Stories**: US-08.2.
**Layout regions**: Navigation Rail → status Tabs (Ouvertes / Acquittées / En cours / Résolues) → prioritized List (severity-sorted per FR-OPS-02: fire/SOS first, visually distinguished with an `errorContainer` leading icon vs. `secondaryContainer` for lower severities) → each row: alert type, station, time-raised, trailing "Acquitter" quick-action button.
**Components**: Navigation Rail, Tabs, List, Buttons (Text/Filled quick-action).
**States**: empty ("Aucune alerte ouverte"), populated, critical-alert-present (a persistent top banner may supplement the list for fire/SOS specifically — never relies on list-scroll-position alone for the most severe alerts).
**Accessibility**: severity is stated in text on every row, not icon/color alone; critical alerts are announced proactively (live region) if the dashboard is open when one arrives.
**RTL**: standard mirroring; severity icon moves to start edge.

## SCR-039 Alert Detail
**Epic/Stories**: US-08.2.
**Layout regions**: Side Sheet (Expanded breakpoint) or full navigation (Compact) → alert metadata (type, severity, station, raised-at) → status-transition action row (Filled Buttons: Acquitter / Marquer en cours / Résoudre, contextually shown per current status) → "Planifier une intervention" link (→ SCR-040, pre-filled with this alert's station).
**Components**: Card, Buttons (Filled), List (metadata rows).
**States**: per-status action-button visibility (state machine: open→acknowledged→in_progress→resolved, matching [ERD Alert entity](../../erd/erd.md#311-alert-src-ext)).
**Accessibility**: current status always stated as text at the top of the sheet, not implied only by which buttons are visible.
**RTL**: side sheet anchors to end edge in LTR, start edge in RTL (opens from the "outer" edge relative to the Nav Rail, consistent with M3 side-sheet RTL convention).

## SCR-040 Maintenance Scheduling
**Epic/Stories**: US-08.3.
**Layout regions**: Navigation Rail → List/calendar-hybrid view of scheduled interventions → "Planifier une intervention" FAB or Filled Button opening a form Dialog (station select, type select, date/time picker, assignee select).
**Components**: Navigation Rail, List, FAB or Filled Button, Dialog (form), Text Field/Dropdown (form fields).
**States**: empty, populated, form-validation-error.
**Accessibility**: date/time picker is keyboard-operable, not touch/mouse-only.
**RTL**: calendar grid mirrors (week starts adapt to locale convention where applicable); form fields mirror.

## SCR-041 Station Occupancy History
**Epic/Stories**: US-08.4.
**Layout regions**: Navigation Rail → station selector → date-range picker → line/bar chart (occupied-cabin-count over time, per [OccupancyHistorySeries](../../api/openapi.yaml)) → below the chart, a summary stat row (peak occupancy, average).
**Components**: Navigation Rail, Dropdown (station select), date-range control, chart (custom, built with M3-token-colored series — chart library choice deferred to Phase 3 implementation), Card (stats).
**States**: loading, no-data-for-range, populated.
**Accessibility**: chart data is also available in a table-equivalent view (toggle), since charts are not reliably screen-reader accessible on their own.
**RTL**: chart X-axis (time) direction is a documented open item — charts conventionally stay LTR (time flows "forward" left-to-right) even in RTL layouts per common data-viz convention; flagged in [Assumptions](../assumptions-and-open-questions.md) as a judgment call, not a hard M3 rule.

## SCR-042 Role / Access Management
**Epic/Stories**: US-08.5.
**Layout regions**: Navigation Rail → List of operator users (name, role, `site_scope`) → "Ajouter un utilisateur" action → row-level "Modifier" action opening a form Dialog (role Dropdown, site-scope multi-select).
**Components**: Navigation Rail, List, Buttons, Dialog (form), Dropdown, Chip (multi-select site scope).
**States**: empty (unlikely — always at least the current admin), populated, form-validation-error.
**Accessibility**: standard form accessibility rules (labels, error association).
**RTL**: standard mirroring.

## Completion Status
✅ All 6 screens in this group specified, including ASCII wireframe for the flagship screen (SCR-037).
