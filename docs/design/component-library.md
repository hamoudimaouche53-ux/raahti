# Component Library Specification

| | |
|---|---|
| **Document ID** | RAH-DOC-035-COMPONENT-LIBRARY |
| **Phase** | Phase 2 — UI/UX Design System and Product Design |
| **Version** | 1.0 |
| **Related** | [Foundations](./foundations.md) · [Design Tokens](../../packages/design-tokens/README.md) · [Screen Inventory](./screen-inventory.md) · [Assumptions §5](./assumptions-and-open-questions.md#5-component-library-scope) |

> Scope note: this phase's deliverable list names Buttons, Inputs, Cards, Lists, Navigation, Dialogs, Sheets "etc." — resolved per [Assumptions §5](./assumptions-and-open-questions.md#5-component-library-scope) to cover every M3 component the [Screen Inventory](./screen-inventory.md) actually requires, plus the three approved bespoke components. All standard components are **M3 baseline, unmodified in structure** — only token *values* (color/shape/type) are RAHATI-specific, per [ADR-0011](../adr/0011-material-design-3-as-design-system.md).

## 1. Buttons

| Variant | Use in RAHATI | Container color | Label color | Shape | Height |
|---|---|---|---|---|---|
| Filled | Primary action per screen ("Payer", "Confirmer", "Voir l'itinéraire") | `primary` | `onPrimary` | `shape-full` | 40dp |
| Filled Tonal | Secondary-emphasis action ("Ajouter aux favoris") | `secondaryContainer` | `onSecondaryContainer` | `shape-full` | 40dp |
| Outlined | Tertiary action, dialogs' "Annuler" | transparent, `outline` border | `primary` | `shape-full` | 40dp |
| Text | Low-emphasis, inline actions ("Voir plus") | transparent | `primary` | `shape-full` | 40dp |
| Elevated | Rare — actions over busy imagery (map overlay controls) | `surfaceContainerLow` | `primary` | `shape-full` | 40dp |
| Icon Button | App-bar actions, list-item trailing actions | transparent | `onSurfaceVariant` | `shape-full` | 40dp target (24dp icon) |
| FAB | Not used for primary navigation actions (bottom nav owns that); reserved for map "recenter" action | `primaryContainer` | `onPrimaryContainer` | `shape-large` | 56dp |

**States**: all buttons use the [state-layer tokens](./foundations.md#8-interaction-states); disabled buttons use `disabled-container`/`disabled-content` opacities over their base color, never a separate gray token.
**Accessibility**: minimum 48×48dp touch target regardless of visual size (40dp visual height gets 4dp invisible padding top/bottom); label text never below `labelLarge`; every icon-only button has an accessible name (screen-reader label), not just a tooltip.
**RTL**: leading/trailing icon positions mirror automatically (leading = start-edge, trailing = end-edge, not "left"/"right").

## 2. Inputs

| Component | Variant | Use |
|---|---|---|
| Text Field | Outlined | Forms: profile edit, review comment, maintenance-intervention notes |
| Search Bar | M3 Search Bar (pill, elevated on focus) | Map screen's bilingual search (FR-MAP-04) |
| Dropdown / Exposed Select | Outlined | Language switcher (FR/AR/EN), filter-detail selects |
| Text Area | Outlined, multi-line | Review comment, verification-document notes |

**Anatomy**: label (floats above on focus/filled), leading icon (optional), trailing icon (clear/error/dropdown-caret), supporting text (helper or error, `bodySmall`), character counter where applicable.
**Validation states**: default, focused (`primary` outline, 2dp), error (`error` outline + supporting text in `error`), disabled (`disabled-container`/`disabled-content`).
**RTL**: label/supporting text align to the reading-direction start edge; leading/trailing icons mirror.

## 3. Cards

| Variant | Use in RAHATI |
|---|---|
| Elevated | Place-summary cards on the map's list view, search results |
| Filled | Slatoki tent-status card (base, before bespoke composition — see §9) |
| Outlined | Operator Dashboard fleet-status rows, Sponsor Dashboard stat cards |

**Anatomy**: optional media (place photo, 16:9), header (title + optional trailing action), body (`bodyMedium`), optional tag/chip row, optional action row (buttons, bottom-aligned).
**Shape**: `shape-medium` (12dp) uniformly.

## 4. Lists

| Variant | Use |
|---|---|
| One-line list item | Notification list (title only) |
| Two-line list item | Favorites list (name + distance), payment-method list |
| Three-line list item | Access-session history (place, date, amount) |

**Anatomy**: leading element (icon/avatar/functional-color dot), headline, supporting text (1–2 lines), trailing element (icon, chip, or value text). Divider: `outlineVariant`, 1dp, inset to align with headline start.

## 5. Navigation

| Component | Use |
|---|---|
| Bottom Navigation Bar | Mobile primary nav: **Map / Slatoki / Emergency / Profile** (RAH-DOC-005 §2.3 fixed order) |
| Top App Bar (Center-aligned / Small) | Place detail, Profile sub-screens, all dialogs' equivalent full-screen forms |
| Navigation Rail | Operator/Sponsor Dashboard (desktop-width web), replacing bottom nav at wide breakpoints — see [Responsive Layout Guidelines](./responsive-layout-guidelines.md) |
| Tabs (Primary) | Slatoki filter tabs (Prayer only / Wudu only / Prayer+Wudu), Operator Dashboard alert-queue status tabs |

**Bottom Navigation Bar detail**: 4 destinations exactly (never 5+, per M3 guidance and RAH-DOC-005's fixed structure); selected item uses filled icon + `onSecondaryContainer` label on `secondaryContainer` pill indicator; unselected uses outlined icon + `onSurfaceVariant` label.
**RTL**: destination order **does not reverse** — Map/Slatoki/Emergency/Profile stays left-to-right in visual reading order in both LTR and RTL (M3 guidance: bottom-nav order is fixed by information hierarchy, not mirrored) but each item's internal icon+label layout mirrors.

## 6. Dialogs & Sheets

| Component | Use |
|---|---|
| Basic Dialog | Confirmations ("Annuler la réservation ?"), destructive-action confirms |
| Full-Screen Dialog | Verification-document upload flow, review-submission flow |
| Bottom Sheet (Modal) | Place detail (from map pin tap), payment method selection, filter chips' detail expansion |
| Side Sheet | Operator Dashboard alert detail (desktop breakpoint only) |

**Bottom Sheet anatomy**: drag handle (top-center, `outlineVariant`), optional header, scrollable body, optional persistent action row. `shape-extra-large` on top corners only (28dp), elevation level 5.
**Accessibility**: dialogs trap focus; Escape/back-gesture dismisses; bottom sheets are reachable and dismissible via screen-reader gestures (not swipe-only).

## 7. Feedback & Status Components

| Component | Use |
|---|---|
| Snackbar | Transient confirmations ("Favori ajouté"), non-blocking errors with optional action ("Réessayer") |
| Badge | Unread-notification count on Profile tab icon |
| Chip — Assist | Map quick filters (Tout/Gratuit/Payant/RAHETI/Slatoki), Slatoki filters |
| Chip — Filter | Multi-select variants of the above (selected = filled with `secondaryContainer`) |
| Chip — Input | Selected tag display (e.g. active search refinements) |
| Progress Indicator — Circular | Loading states (map data fetch, payment processing) |
| Progress Indicator — Linear | QR-scan-to-unlock sequence progress (determinate, 4 steps) |

**Snackbar**: max 2 lines, auto-dismiss 4–10s (per M3 guidance, longer if it carries an action), never stacks more than one at a time — a new snackbar replaces the previous.

## 8. Controls

| Component | Use |
|---|---|
| Switch | Settings toggles (notification preferences, availability-follow on Favorites) |
| Checkbox | Multi-select contexts (rare in V1 — filter chips are preferred per M3 guidance for filtering) |
| Radio Button | Single-select groups (payment method selection list) |
| Segmented Button | Emergency Mode profile toggle (V1: single segment "Diabétique", ready for future profiles per PRD §13) |

## 9. Bespoke Composed Components (the only 3 non-M3-catalog components)

Each is built **entirely from M3 primitives** — no custom-drawn chrome, borders, or shadows outside the token set.

### 9.1 Qibla Compass
- **Composition**: a circular `Card` (elevated, level 3) containing a custom-drawn compass rose (SVG, using `outline`/`primary` tokens for rings and ticks) + a custom needle glyph (§ [Foundations §3](./foundations.md#3-iconography)) colored `slatoki` (functional color, since this is exclusively a Slatoki-context component) + a center label (`titleMedium`) showing degrees.
- **States**: calibrating (needle pulses via `motion` medium-2 opacity loop), locked (needle solid), magnetometer-unavailable (fallback: static compass + `errorContainer` banner "Boussole indisponible sur cet appareil").
- **Widget mode**: home-screen widget variant is a compact `Card` (80×80dp) with a simplified needle-only rendering.

### 9.2 Slatoki Tent-Status Card
- **Composition**: `Card` (filled variant) + leading icon (custom tent glyph, `slatoki` color) + two-line list content (deployment status headline, capacity/amenities supporting text) + trailing `Chip` (Assist, showing "Déployée"/"Repliée" state, colored via `slatoki`/`slatokiContainer`).
- **States**: deployed (chip filled `slatoki`), folded (chip outlined, `onSurfaceVariant`), amenity icons (lighting bulb, curtain) shown as small (`18dp`) inline icons in the supporting text row, each with a screen-reader label ("Éclairage disponible").

### 9.3 Cabin-Status Indicator
- **Composition**: a small (24dp) circular dot (functional color: `success` = free, `error` = occupied, `outline` = out-of-service) + adjacent `labelMedium` text ("Libre"/"Occupé"/"Hors service") — used inline in Place Detail's cabin list and on the Operator Dashboard's fleet table.
- **Never color-only**: the text label is **mandatory**, not decorative — color alone never conveys occupancy state, satisfying WCAG 2.2 AA's "use of color" success criterion (1.4.1) for users with color-vision deficiency.

## 10. Accessibility Checklist (applies to every component above)

- [ ] Minimum 48×48dp touch target.
- [ ] Text contrast ≥ 4.5:1 (body), ≥ 3:1 (large text ≥18pt/14pt-bold, and graphical/icon elements).
- [ ] Focus indicator ≥ 2px, ≥ 3:1 contrast, never fully obscured (WCAG 2.2 SC 2.4.11).
- [ ] No information conveyed by color alone (§9.3 pattern applied wherever a functional color appears).
- [ ] Every interactive element has an accessible name; every image/icon conveying meaning has alt text/screen-reader label.
- [ ] RTL mirroring verified for every component with directional content (leading/trailing icons, alignment).

## 11. Completion Status

| Item | Status |
|---|---|
| Buttons, Inputs, Cards, Lists, Navigation, Dialogs, Sheets specified | ✅ Complete |
| Feedback/status and control components specified (scope-completion per Assumptions §5) | ✅ Complete |
| 3 bespoke composed components specified, each traced to an M3-extension rule | ✅ Complete |
| Accessibility checklist applied system-wide | ✅ Complete |

**Phase 2 deliverable 3 of 10 — Component Library Specification: COMPLETE.**
