# Wireframes — Mobile: Slatoki

| | |
|---|---|
| **Group** | Mobile Application — Slatoki (EPIC-02) |
| **Related** | [Screen Inventory](../screen-inventory.md) · [User Flows §2](../user-flows.md#2-slatoki-epic-02) · [Component Library §9.1](../component-library.md#91-qibla-compass) |

---

## SCR-008 Slatoki Tab (list + Qibla widget) — **FLAGSHIP**
**Epic/Stories**: US-02.1.1, 02.1.3, 02.1.4, 02.1.5.
**Layout regions**: Top App Bar (title "Slatoki", `slatoki` functional-color accent underline distinguishing this tab from the rest of the app) → compact Qibla Compass widget card (80×80dp, tap to expand to SCR-009) pinned near top → filter Tab row (Prière seule / Wudu seul / Prière + Wudu) → scrollable list of Slatoki Tent-Status Cards (RAHETI units) and verified-mosque list items, mixed, sorted by distance.
**Components**: Top App Bar, Qibla Compass (bespoke, compact mode), Tabs (Primary), Slatoki Tent-Status Card (bespoke), List (two-line, for mosques).
**States**: no Slatoki-qualified places nearby (empty state, illustration + "Aucun espace Slatoki à proximité"), tent-status live-updating (real-time badge change without full list re-render/scroll-jump).
**Accessibility**: the tab's distinct magenta accent is never the only wayfinding signal — the bottom-nav label "Slatoki" (text) is always present alongside the icon and color.
**RTL**: filter tab row and list mirror; Qibla widget card position stays visually consistent (compass content itself follows §RTL rule in SCR-009).

```
ASCII wireframe (flagship):

┌─────────────────────────────┐
│ Slatoki صلاتكِ           ▬   │ <- magenta accent underline
│  ┌────┐                      │
│  │ 🧭 │ tap to expand         │ <- compact Qibla widget
│  └────┘                      │
│ [Prière][Wudu][Prière+Wudu]  │ <- filter tabs
│ ▣ Tente RAHETI — Déployée     │ <- Slatoki tent-status card
│   4 tapis · 💡 · 🚪           │
│ ▤ Mosquée El Nour  Femmes✓    │ <- verified mosque list item
└─────────────────────────────┘
```

## SCR-009 Qibla Full-Screen — **FLAGSHIP**
**Epic/Stories**: US-02.1.2.
**Layout regions**: full-screen, minimal chrome — Top App Bar (back action only, transparent/scrim over background) → centered, large Qibla Compass (240dp) dominating the screen → below it, degree readout (`titleMedium`) and calibration hint text if needed.
**Components**: Top App Bar (transparent), Qibla Compass (bespoke, full-screen mode).
**States**: calibrating (needle pulses, hint text "Déplacez votre téléphone en 8 pour calibrer"), locked (steady needle, no hint), magnetometer-unavailable (static compass + `errorContainer` banner, per [Component Library §9.1](../component-library.md#91-qibla-compass)).
**Accessibility**: bearing is also announced numerically for screen-reader users ("La Mecque est à 127 degrés, sud-est") — the compass is not a screen-reader-only-decorative element.
**RTL**: the compass rose itself is direction-agnostic (a real-world bearing, not a text element) and does **not** mirror; only the surrounding chrome (back button position, degree-readout text alignment) follows RTL.

```
ASCII wireframe (flagship):

┌─────────────────────────────┐
│ ←                             │
│                               │
│         ╱╲                   │
│        ╱  ╲   N               │
│       │ 🧭 │                  │  <- large compass, 240dp
│        ╲  ╱                   │
│         ╲╱                   │
│                               │
│        127° — La Mecque       │
└─────────────────────────────┘
```

## SCR-010 Slatoki Place Detail (verified mosque / RAHETI tent)
**Epic/Stories**: US-02.1.4, 02.1.5.
**Layout regions**: same Bottom Sheet base as SCR-005/006, with Slatoki-specific additions: a "Femmes — section confirmée" `Chip` (filled `slatoki`/`onSlatoki`) prominently placed directly under the header (not buried in the generic tag row) when `womenVerificationLevel = verified_confirmed`; for RAHETI tents, the full Slatoki Tent-Status Card (§ SCR-008) embedded inline instead of a generic Cabin-Status Indicator.
**Components**: Bottom Sheet, Chip (Assist, `slatoki` color), Slatoki Tent-Status Card (bespoke), Buttons (Outlined "Itinéraire").
**States**: verified vs. generic mosque (verified shows the confirmation chip prominently; generic shows a neutral "Statut femmes non confirmé" `bodySmall` note instead — informational, not alarming in tone).
**Accessibility**: the verification chip's meaning is conveyed in text, not the magenta color alone.
**RTL**: identical mirroring rules to SCR-005.

## Completion Status
✅ All 3 screens in this group specified, including ASCII wireframes for both flagship screens (SCR-008, SCR-009).
