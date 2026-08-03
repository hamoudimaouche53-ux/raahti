# Wireframes — Sponsor Dashboard

| | |
|---|---|
| **Group** | Sponsor Dashboard (EPIC-09) |
| **Related** | [Screen Inventory](../screen-inventory.md) · [User Flows §9](../user-flows.md#9-sponsor-dashboard-epic-09) · [Domain Model §9 invariant](../../architecture/domain-model.md#9-bounded-context-sponsorship) (no PII) |

> Read-only surface throughout — no create/edit/delete affordances anywhere in this group, matching FR-SPN-04's strict aggregation rule.

---

## SCR-043 Sponsor Stats Overview — **FLAGSHIP**
**Epic/Stories**: US-09.1, 09.4.
**Layout regions**: Navigation Rail (Statistiques, Rapports, Carte) → campaign/period selector (Dropdown) → stat-card row (fréquentation estimée, durée d'exposition, zone géographique — exactly [SponsorStats](../../api/openapi.yaml)'s three aggregate fields, nothing more) → trend chart (frequentation over the campaign period) → explicit "Aucune donnée personnelle affichée" footnote, permanently visible (not just a policy statement elsewhere) as a trust signal matching FR-SPN-04.
**Components**: Navigation Rail, Dropdown, Card (stat cards), chart (aggregate trend only).
**States**: campaign-active, campaign-completed (historical view, no live-updating chart), no-active-campaign (empty state).
**Accessibility**: stat cards' numeric values have full text labels (not icon/number-only); chart has a table-equivalent view, per the same rule as SCR-041.
**RTL**: standard mirroring; the "no PII" footnote remains present and legible in every language (natively authored per ADR-0017, not machine-translated).

```
ASCII wireframe (flagship, expanded breakpoint):

┌───┬─────────────────────────────────────────┐
│ ▤ │ Statistiques   Campagne: [Été 2026 ▾]     │
│Stats   │ ┌───────────┐┌───────────┐┌───────────┐│
│Rapports│ │Fréquent.   ││Exposition  ││Zone        ││
│Carte   │ │  12 400    ││  340h      ││Centre-ville││
│        │ └───────────┘└───────────┘└───────────┘│
│        │  📈 Tendance sur la période             │
│        │  ⓘ Aucune donnée personnelle affichée   │
└───┴─────────────────────────────────────────┘
```

## SCR-044 Campaign Report Export
**Epic/Stories**: US-09.2.
**Layout regions**: Navigation Rail → campaign selector → report preview (same stat cards as SCR-043, scoped to the selected campaign/tier) → export action row: format Segmented Button (JSON/CSV/PDF, per [openapi.yaml](../../api/openapi.yaml)'s `format` parameter) + Filled Button "Exporter".
**Components**: Navigation Rail, Dropdown, Segmented Button, Buttons (Filled), Card.
**States**: generating (progress indicator on the export button), ready-for-download, export-failed (Snackbar with retry).
**Accessibility**: export format selection is keyboard-operable; download completion is announced.
**RTL**: standard mirroring.

## SCR-045 Sponsored Stations Map
**Epic/Stories**: US-09.3.
**Layout regions**: Navigation Rail → map (reuses SCR-033's map component) filtered to only the sponsor's linked stations (via `SPONSOR_STATION` per [ERD](../../erd/erd.md)) → side list of sponsored stations (name, zone — no occupancy/cabin-level detail, since that would edge toward operational rather than visibility data).
**Components**: Navigation Rail, map canvas (filtered), Card (side-list).
**States**: standard, empty (campaign with zero linked stations — an edge case, but defined).
**Accessibility**: same list-view-alternative rule as SCR-003/033.
**RTL**: side panel/map mirroring per SCR-033's rule.

## Completion Status
✅ All 3 screens in this group specified, including ASCII wireframe for the flagship screen (SCR-043).
