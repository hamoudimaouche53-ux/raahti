# Wireframes — Mobile: Emergency Mode & Payment/Unlock Journey

| | |
|---|---|
| **Group** | Mobile Application — Mode Urgence (EPIC-03) + Payment & Unlock (EPIC-04) |
| **Related** | [Screen Inventory](../screen-inventory.md) · [User Flows §3–4](../user-flows.md#3-mode-urgence-epic-03) · [Sequence Diagram §1](../../architecture/sequence-diagrams.md#1-qr-scan--payment--unlock-incl-failurerefund-path) |

---

## SCR-011 Emergency Mode Result — **FLAGSHIP**
**Epic/Stories**: US-03.1, 03.2.
**Layout regions**: reached in one tap from bottom nav, no intermediate screen (FR-EMG-01) — this screen **is** the destination. Top App Bar (title "Urgence", `error`-adjacent but not `error`-colored chrome — urgency without alarm) → prominent single result card: nearest facility name, distance, ETA-on-foot → if `discountEligible = true`, a visible `successContainer` badge "Réduction 50% disponible" → large Filled Button "Aller au lieu le plus proche" (routes into SCR-013 QR flow or external navigation depending on RAHETI-unit vs. third-party).
**Components**: Top App Bar, Card (elevated, single result — not a list, since exactly one facility is shown per FR-EMG-02), Chip/Badge (discount indicator), Buttons (Filled).
**States**: verified-diabetic-with-discount, verified-but-not-yet-nearest-is-free (discount badge absent, no error — just not shown), location-permission-denied (fallback message + settings-deep-link button).
**Accessibility**: the discount badge text is explicit ("Réduction 50% disponible"), never conveyed by badge color alone; the whole flow is reachable in ≤2 focus stops from app launch for screen-reader users, matching the "one tap" spirit of FR-EMG-01.
**RTL**: card content and button mirror; distance/ETA numerals remain LTR internally per standard numeral-direction convention even inside RTL text.

```
ASCII wireframe (flagship):

┌─────────────────────────────┐
│ Urgence                       │
│ ┌───────────────────────────┐│
│ │ Station Didouche            ││
│ │ 180 m · 2 min à pied         ││
│ │ [ Réduction 50% disponible ] ││
│ └───────────────────────────┘│
│                               │
│  [   Aller au lieu le plus    ]│
│  [        proche              ]│
└─────────────────────────────┘
```

## SCR-012 Emergency Discount Confirmation (in-flow)
**Epic/Stories**: US-03.3.
**Layout regions**: not a standalone route — this is a **state of SCR-015** (Payment Method Selection): when the session originated from SCR-011, the price row shows a struck-through original price next to the discounted price, with a small `successContainer` "Urgence -50%" chip inline.
**Components**: reuses SCR-015's components + Chip (discount indicator).
**States**: discount applied (shown), discount not applicable (normal SCR-015, no special treatment).
**Accessibility**: struck-through price has an explicit screen-reader alternative ("Prix original 100 DZD, remise de 50%, total 50 DZD") — strikethrough styling alone is not accessible.
**RTL**: price row mirrors; struck-through and discounted amounts keep their relative order reversed correctly (start-to-end reading order still shows original-then-discounted).

## SCR-013 QR Scanner — **FLAGSHIP**
**Epic/Stories**: US-04.1.
**Layout regions**: full-screen camera viewfinder → centered scan-target frame (square, rounded `shape-medium` corners, `primary`-colored outline) → Top App Bar (transparent, back action only) → bottom overlay strip with a short instruction (`bodyMedium`, high-contrast scrim background) "Scannez le QR code sur la cabine".
**Components**: Top App Bar (transparent), custom camera-viewfinder container (platform camera preview, not an M3 catalog component — chrome around it is M3).
**States**: scanning (frame pulses gently), recognized (frame flashes `success` briefly before transition to SCR-014), permission-denied (camera-access rationale card + settings deep-link, replacing the viewfinder).
**Accessibility**: camera-based QR scanning has no reliable non-visual equivalent — an explicit alternative entry point ("Saisir le code manuellement", a text-input fallback) is provided as a Text Button below the instruction strip, so the flow is not visually-only.
**RTL**: instruction text and back button mirror; scan-target frame itself is direction-agnostic (centered square).

```
ASCII wireframe (flagship):

┌─────────────────────────────┐
│ ←                             │
│                               │
│      ┌───────────┐            │
│      │           │            │  <- scan target frame
│      │           │            │
│      └───────────┘            │
│                               │
│  Scannez le QR code sur la    │
│  cabine                       │
│  [ Saisir le code manuellement ]│
└─────────────────────────────┘
```

## SCR-014 Cabin Availability Confirmation
**Epic/Stories**: US-04.2.
**Layout regions**: brief transitional screen/sheet — Cabin-Status Indicator (large, centered) + cabin code + station name → auto-advances to SCR-015 or SCR-018 (unavailable) within ~1s, no user action required unless it fails.
**Components**: Cabin-Status Indicator (bespoke), Progress Indicator (circular, brief).
**States**: available (auto-advance), unavailable (stops here, shows `errorContainer` message "Cette cabine n'est plus disponible" + Filled Button "Retour à la carte").
**Accessibility**: transient state changes are announced, not just visually flashed.
**RTL**: standard mirroring, no special cases.

## SCR-015 Payment Method Selection Sheet — **FLAGSHIP**
**Epic/Stories**: US-04.3.
**Layout regions**: Modal Bottom Sheet → header ("Choisir un moyen de paiement") → Radio-button list of saved Payment Methods (card/wallet icon + masked identifier) → "Ajouter un moyen de paiement" list item (routes to an external provider-hosted flow — provider-agnostic per [ADR-0014](../../adr/0014-payment-provider-abstraction.md), the exact hosted-flow UI is provider-owned, not RAHATI-designed) → price summary row (with discount treatment per SCR-012 if applicable) → bottom-anchored Filled Button "Payer [montant]".
**Components**: Bottom Sheet, Radio Button, List, Chip (discount), Buttons (Filled).
**States**: no saved methods (only "Ajouter un moyen de paiement" shown, pay button disabled until one is added), free cabin (this screen is skipped entirely per the flow in [User Flows §4](../user-flows.md#4-payment--unlock-journey-epic-04)).
**Accessibility**: radio group is a single accessible group with clear selection announcement; masked card identifiers include enough context to be distinguishable by screen reader ("Visa se terminant par 4242").
**RTL**: radio buttons and list content mirror; price summary row mirrors per SCR-012's rule.

```
ASCII wireframe (flagship):

┌─────────────────────────────┐
│           ▬▬▬                │
│ Choisir un moyen de paiement  │
│ ○ Visa •••• 4242              │
│ ○ Wallet Mobile               │
│ + Ajouter un moyen de paiement│
│ ─────────────────────────────│
│ Total: 50 DZD                 │
│  [        Payer 50 DZD       ]│
└─────────────────────────────┘
```

## SCR-016 Payment Processing (loading)
**Epic/Stories**: US-04.3.
**Layout regions**: minimal — centered circular Progress Indicator (indeterminate) + `bodyMedium` status text "Traitement du paiement..." → screen is non-interactive (no back gesture) while processing, per [Idempotency-Key](../../api/api-architecture.md#8-idempotency)-backed request in flight.
**Components**: Progress Indicator — Circular.
**States**: processing only — this state resolves to SCR-017 (success) or SCR-018 (failure); it is never a terminal/parked state.
**Accessibility**: "processing, please wait" is announced once; the screen intentionally blocks back-navigation, which is itself announced so screen-reader users aren't confused by an unresponsive back gesture.
**RTL**: symmetric, no direction-dependent content.

## SCR-017 Unlock Confirmation / Access Active — **FLAGSHIP**
**Epic/Stories**: US-04.4, 04.5.
**Layout regions**: full-screen confirmation — large `success`-colored check-circle icon → headline "Cabine déverrouillée" → cabin code + station name → linear Progress Indicator (determinate, showing the 4-step unlock sequence per [Foundations §7 — Feedback Components](../component-library.md#7-feedback--status-components)) transitioning to a simple "Session en cours" state once unlocked → Text Button "J'ai terminé" (manually triggers SCR-019, in addition to automatic door-sensor detection).
**Components**: Progress Indicator — Linear (determinate), Buttons (Text), custom success icon composition (Icon + functional `success` color).
**States**: unlocking (linear progress animating), unlocked/in-use (steady, session timer optionally shown), unlock-failed (routes to SCR-018 with the refund-notice variant, per the Phase 1 sequence diagram's failure branch).
**Accessibility**: unlock success is announced immediately and unambiguously ("Cabine déverrouillée avec succès"), not conveyed by icon/color alone.
**RTL**: standard mirroring; progress bar fills start-to-end (right-to-left in AR), matching platform-native progress-indicator RTL behavior.

```
ASCII wireframe (flagship):

┌─────────────────────────────┐
│                               │
│           ✅                  │
│     Cabine déverrouillée      │
│     Station Didouche · C-014  │
│  ▓▓▓▓▓▓▓▓░░░░  Session en cours│
│                               │
│      [ J'ai terminé ]         │
└─────────────────────────────┘
```

## SCR-018 Payment Failed / Refund Notice
**Epic/Stories**: US-04.3 (error path), also reached from SCR-017's unlock-failure branch.
**Layout regions**: full-screen — `error`-colored alert icon → headline (varies: "Paiement refusé" or "Déverrouillage échoué — remboursement en cours") → `bodyMedium` explanation (maps to the `ProblemDetail.code` from [API Architecture §7](../../api/api-architecture.md#7-error-schema), never a raw technical error string) → Filled Button "Réessayer" + Text Button "Retour à la carte".
**Components**: Buttons (Filled, Text), custom error icon composition.
**States**: payment-declined (retry re-opens SCR-015), unlock-failed-refunded (retry re-opens SCR-013 QR scan, since the cabin state must be re-verified — matches the Phase 1 refund sequence diagram's logic, not a naive "just retry payment").
**Accessibility**: error explanation is in natively-authored, plain language per [Cross-Cutting Architecture — Error Handling](../../architecture/cross-cutting-architecture.md#error-handling), never a raw error code shown to the user.
**RTL**: standard mirroring.

## SCR-019 Session Complete / Exit Confirmation
**Epic/Stories**: US-04.6.
**Layout regions**: brief confirmation — check icon → "Session terminée" → transaction summary (amount charged, duration) → Filled Button "Laisser un avis" (routes to SCR-007) + Text Button "Retour à la carte".
**Components**: Buttons (Filled, Text), List (transaction summary rows).
**States**: auto-triggered by door-sensor close event (per FR-PAY-06) or by the manual "J'ai terminé" action from SCR-017 — visually identical either way.
**Accessibility**: summary values (amount, duration) are read in full by screen reader, not abbreviated.
**RTL**: standard mirroring.

## Completion Status
✅ All 9 screens in this group specified, including ASCII wireframes for all 4 flagship screens (SCR-011, SCR-013, SCR-015, SCR-017).
