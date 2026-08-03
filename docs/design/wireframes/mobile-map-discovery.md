# Wireframes — Mobile: Map & Discovery

| | |
|---|---|
| **Group** | Mobile Application — Map & Discovery (EPIC-01) |
| **Related** | [Screen Inventory](../screen-inventory.md) · [User Flows §1](../user-flows.md#1-map--discovery-epic-01) · [Component Library](../component-library.md) |

---

## SCR-001 Splash / Launch
**Epic/Stories**: app-shell.
**Layout regions**: Full-bleed `surface` background → centered RAHATI logo mark (`space-16` from top third) → below it, app name (`headlineSmall`) → bottom-anchored circular `Progress Indicator` (indeterminate) at `space-8` from bottom safe area.
**Components**: Progress Indicator — Circular.
**States**: loading only (max 2s target, then routes to SCR-003 or SCR-002).
**Accessibility**: logo has an accessible name; loading state announced to screen readers ("RAHATI, chargement").
**RTL**: symmetric layout, no direction-dependent elements.

## SCR-002 Onboarding — permissions primer
**Epic/Stories**: US-01.1.1 (supports).
**Layout regions**: Top App Bar (skip action, end-aligned) → illustration (`space-12` height) → headline (`headlineSmall`) + body copy explaining location/notification permission rationale → bottom-anchored primary Filled Button ("Continuer") + Text Button ("Plus tard").
**Components**: Top App Bar, Buttons (Filled, Text).
**States**: 2–3 sequential cards (location rationale, notification rationale) — paginated via a simple dot indicator, not a full carousel component.
**Accessibility**: each card's illustration has a text alternative; page position announced ("Étape 1 sur 2").
**RTL**: skip action mirrors to start edge; pagination dots direction-agnostic (centered).

## SCR-003 Map (Home) — **FLAGSHIP**
**Epic/Stories**: US-01.1.1…01.1.7.
**Layout regions** (compact/mobile): Full-bleed map (z-0) → floating Search Bar pinned `space-4` from top safe area → horizontal scrollable Filter Chip row directly below search bar → floating recenter FAB, end-edge, `space-4` above bottom nav → Bottom Navigation Bar (persistent, 4 destinations) pinned to bottom safe area → color-coded pins per [Foundations §1.2](../foundations.md#12-brand-functional-color-extension-rah-doc-002-4-2-preserved-per-adr-0011).
**Components**: Search Bar, Chip (Filter, multi-select), FAB, Bottom Navigation Bar, custom map pin markers (functional colors).
**States**: default (populated), loading (skeleton pins fade in), empty (no results — small `bodyMedium` message, not a full empty-state illustration since the map itself is never truly empty), offline (see SCR-031).
**Accessibility**: each pin is independently focusable/reachable via screen-reader (not just visually tappable); a "list view" toggle (icon button, top-end) provides a fully linear, screen-reader-friendly alternative to spatial map exploration — this is a wireframe-level accessibility requirement, not optional.
**RTL**: search bar and filter-chip row mirror (chips scroll start-to-end, i.e. right-to-left in AR); recenter FAB moves to the start edge (left in AR) so it never conflicts with a RTL-mirrored bottom-nav item.

```
ASCII wireframe (compact, light) — annotated regions only, not pixel-accurate:

┌─────────────────────────────┐
│ [ Search: rechercher... 🔍]  │  <- Search Bar, space-4 margin
│ (Tout)(Gratuit)(Payant)...   │  <- Filter chip row, scrollable
│                               │
│         🟢    🔵             │
│              🟣               │  <- Map canvas, full-bleed
│      🟠         🟢            │
│                          [+] │  <- Recenter FAB, end-edge
├─────────────────────────────┤
│  🗺️Map  🕌Slatoki 🚨Urgence 👤Profil │ <- Bottom Nav, 4 destinations
└─────────────────────────────┘
```

## SCR-004 Search results / suggestions overlay
**Epic/Stories**: US-01.1.4.
**Layout regions**: Search Bar (now expanded/focused, elevated per M3 Search Bar spec) → scrollable suggestion List (one-line items: place name + distance chip) below it, overlaying the map.
**Components**: Search Bar (expanded), List (one-line item).
**States**: typing (live suggestions), no matches (`bodyMedium` "Aucun résultat"), recent searches (shown before typing starts).
**Accessibility**: suggestion count announced as the list updates ("5 résultats").
**RTL**: text input caret and suggestion list both mirror to RTL reading order.

## SCR-005 Place Detail Sheet — Station (RAHETI unit) — **FLAGSHIP**
**Epic/Stories**: US-01.2.1…01.2.5.
**Layout regions**: Modal Bottom Sheet, drag handle top-center → header row (place name bilingual/trilingual, close button end-aligned) → rating row (stars + review count) → status row (Cabin-Status Indicator per cabin, if RAHETI unit — see [Component Library §9.3](../component-library.md#93-cabin-status-indicator)) → tag Chip row (Women ✓, Wudu ✓, PMR, Open/Closed) → price/access-type row → action row (Filled Button "Scanner le QR" if RAHETI unit, Outlined Button "Itinéraire").
**Components**: Bottom Sheet, Cabin-Status Indicator (bespoke), Chip (Assist), Buttons (Filled, Outlined), List (for cabin rows if multiple).
**States**: single-cabin vs. multi-cabin layout (cabin list becomes scrollable past ~4 rows), no-reviews-yet state.
**Accessibility**: sheet is reachable/dismissible via screen-reader gesture, not swipe-only; cabin status never color-only (label text mandatory, per [Component Library §9.3](../component-library.md#93-cabin-status-indicator)).
**RTL**: header close button moves to start edge; rating stars render in fixed LTR internal order (a rating is not a "sentence," so it does not mirror) per M3 RTL guidance.

```
ASCII wireframe (flagship) — annotated regions only:

┌─────────────────────────────┐
│           ▬▬▬                │  <- drag handle
│ Station Didouche  ★4.6 (32) ⨉│
│ [Femmes✓][Wudu✓][PMR]        │  <- tag chips
│ ● Cabine 1  Libre             │  <- cabin-status indicator
│ ● Cabine 2  Occupé            │
│ 50 DZD · Carte, Wallet        │
│ [ Scanner le QR ]  [Itinéraire]│
└─────────────────────────────┘
```

## SCR-006 Place Detail Sheet — Third-Party Place (variant of SCR-005)
**Epic/Stories**: US-01.2.1…01.2.4.
**Difference from SCR-005**: no Cabin-Status Indicator row (third-party places have no cabins); status row instead shows a single declarative Open/Closed `Chip`, visually distinct (outlined, not filled) from RAHETI units' IoT-verified status, per RAH-DOC-005 §2.2's explicit distinction requirement; no "Scanner le QR" action (third-party places are never RAHETI QR-unlockable) — only "Itinéraire".
**Everything else** (header, rating, tags, RTL/accessibility rules) is identical to SCR-005.

## SCR-007 Submit Review
**Epic/Stories**: US-05.2.
**Layout regions**: Top App Bar ("Ajouter un avis", close action) → star-rating input (large touch targets, 48dp per star) → multi-line Text Area ("Votre commentaire") → bottom-anchored Filled Button ("Publier").
**Components**: Top App Bar, Text Area, Buttons (Filled).
**States**: empty (button disabled until a rating is selected), submitting (button shows inline progress), success (returns to SCR-005/006 with a Snackbar "Avis publié").
**Accessibility**: star rating is operable via keyboard/screen-reader (not drag-only) — each star individually focusable with an accessible name ("3 étoiles sur 5").
**RTL**: star row renders in fixed LTR internal order (same rule as SCR-005's rating display); text area follows RTL text direction for Arabic input.

## SCR-031 Offline / Empty / Error States
**Epic/Stories**: US-01.1.7.
**Layout regions**: reuses SCR-003's exact layout — this is a **state**, not a separate screen route — with: (a) a top banner (`errorContainer`/`onErrorContainer`, `bodySmall`) reading "Hors connexion — dernières données affichées, mise à jour il y a Xmin" per FR-MAP-07's freshness-indicator requirement; (b) cached pins rendered at reduced opacity (85%) to visually signal staleness without relying on the banner text alone.
**Components**: banner (custom, built from `Card` + `Icon` + `bodySmall` text — not a distinct M3 catalog component), existing SCR-003 components.
**States**: reconnecting (banner shows a small inline Progress Indicator), reconnected (banner dismisses with a `short-3` fade).
**Accessibility**: banner is announced once on appearance (not repeated on every re-render); reduced pin opacity is a supplementary, not sole, staleness signal (text banner is the primary one, satisfying "no information by appearance alone").
**RTL**: banner icon+text row mirrors.

## Completion Status
✅ All 8 screens in this group specified — structural regions, components, states, accessibility, RTL for every screen; ASCII wireframe for both flagship screens (SCR-003, SCR-005).
