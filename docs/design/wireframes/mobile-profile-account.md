# Wireframes — Mobile: Profile, Account & Settings

| | |
|---|---|
| **Group** | Mobile Application — User Profile & Account (EPIC-05) + Bilingual/Theme (EPIC-06) + Notifications (EPIC-10 UI) |
| **Related** | [Screen Inventory](../screen-inventory.md) · [User Flows §5–6](../user-flows.md#5-profile--account-epic-05) |

---

## SCR-020 Profile / Account Home — **FLAGSHIP**
**Epic/Stories**: US-05.1, 05.2.
**Layout regions**: Top App Bar ("Profil") → account summary card (avatar/initial, name or "Compte invité" if guest, verified-diabetic badge if applicable) → sectioned List: Historique des visites (→SCR-021), Moyens de paiement (→SCR-022), Mes avis (→SCR-023), Statut diabétique vérifié (→SCR-024/025), Favoris (→SCR-026), Notifications (→SCR-028), Langue et thème (→SCR-029) → if guest, a persistent "Se connecter" Filled Button instead of the sectioned list's account-bound items being fully hidden (they show a lock affordance instead, communicating what registration unlocks).
**Components**: Card, List (one-line, with leading icons + trailing chevron), Chip/Badge (verified-diabetic indicator), Buttons (Filled, for guest sign-in prompt).
**States**: guest (locked sections visible-but-disabled, not hidden — supports FR-USR-01's "optional, not required" framing without hiding value), registered, registered-with-verified-diabetic-badge.
**Accessibility**: locked/disabled list items announce why ("Connexion requise") rather than silently doing nothing on tap.
**RTL**: list leading icon and trailing chevron both mirror to start/end edges respectively.

```
ASCII wireframe (flagship):

┌─────────────────────────────┐
│ Profil                        │
│  (A)  Amina B.                │
│       ✓ Diabétique vérifié     │
│ ▤ Historique des visites    › │
│ ▤ Moyens de paiement        › │
│ ▤ Mes avis                  › │
│ ▤ Statut diabétique         › │
│ ▤ Favoris                   › │
│ ▤ Notifications             › │
│ ▤ Langue et thème           › │
└─────────────────────────────┘
```

## SCR-021 Visit History
**Epic/Stories**: US-05.2.
**Layout regions**: Top App Bar (back) → chronological List (three-line items: place name, date, amount/free) grouped by month with `titleSmall` section headers.
**Components**: Top App Bar, List (three-line, sectioned).
**States**: empty ("Aucune visite pour le moment"), populated.
**Accessibility**: section headers are exposed as list-section semantics for screen readers, not just visual dividers.
**RTL**: standard mirroring; dates render per the active locale's date format (FR/EN Gregorian, AR Gregorian by default — Hijri calendar is out of scope unless separately requested).

## SCR-022 Saved Payment Methods
**Epic/Stories**: US-05.2.
**Layout regions**: Top App Bar (back) → List (two-line: method type + masked identifier, trailing "Par défaut" chip or "Définir par défaut" text action, swipe-to-delete or trailing delete icon button) → bottom "Ajouter un moyen de paiement" list item.
**Components**: List, Chip, Icon Button (delete), Buttons (Text, for add action).
**States**: empty, populated, delete-confirmation (Basic Dialog "Supprimer ce moyen de paiement ?").
**Accessibility**: swipe-to-delete has a non-gesture equivalent (visible delete icon button) — never gesture-only.
**RTL**: swipe direction mirrors (swipe toward start edge to reveal delete in both directions, consistent with platform RTL list conventions).

## SCR-023 My Reviews
**Epic/Stories**: US-05.2.
**Layout regions**: Top App Bar (back) → List (two-line: place name + star rating, trailing edit/delete icon buttons).
**Components**: List, Icon Button.
**States**: empty, populated.
**Accessibility**: standard.
**RTL**: standard mirroring.

## SCR-024 Diabetic Verification Submission — **FLAGSHIP**
**Epic/Stories**: US-05.3.
**Layout regions**: Top App Bar ("Vérification statut diabétique", back) → explanatory `bodyMedium` copy (what's needed, why — data-shape only per [ADR-0010](../../adr/0010-diabetic-verification-mechanism.md), review-process language deliberately generic since the mechanism itself is undecided) → document-upload card (camera/file-picker entry point, thumbnail preview once selected) → Filled Button "Soumettre".
**Components**: Card (upload target), Buttons (Filled), Progress Indicator (upload in progress).
**States**: no-document-selected (submit disabled), selected-preview, uploading, submitted (routes to SCR-025).
**Accessibility**: upload card is operable via both camera and file picker, not camera-only, so it works for users without camera access; upload progress announced.
**RTL**: standard mirroring; copy is natively authored per language (no machine translation, per FR-I18N-03/ADR-0017).

```
ASCII wireframe (flagship):

┌─────────────────────────────┐
│ ← Vérification statut         │
│   diabétique                  │
│ Téléversez un justificatif    │
│ médical pour bénéficier du    │
│ Mode Urgence.                 │
│ ┌───────────────────────────┐│
│ │   📷  Ajouter un document  ││
│ └───────────────────────────┘│
│      [     Soumettre        ]│
└─────────────────────────────┘
```

## SCR-025 Diabetic Verification Status
**Epic/Stories**: US-05.3.
**Layout regions**: Top App Bar (back) → status Card: large status icon/chip (pending = `secondaryContainer`, approved = `successContainer`, rejected = `errorContainer`) + status label + submission date + (if rejected) resubmission Filled Button.
**Components**: Card, Chip (status), Buttons (Filled, conditional).
**States**: pending, approved, rejected.
**Accessibility**: status is stated in text, never conveyed by chip color alone.
**RTL**: standard mirroring.

## SCR-026 Favorites List
**Epic/Stories**: US-05.4.
**Layout regions**: Top App Bar ("Favoris") → List (two-line: place name + distance, trailing Switch for "Me notifier si disponible").
**Components**: List, Switch.
**States**: empty ("Aucun favori — ajoutez-en depuis la fiche lieu"), populated.
**Accessibility**: switch state and label are read together ("Me notifier si disponible, activé").
**RTL**: switch track/thumb direction mirrors per platform RTL switch convention.

## SCR-027 Notification Settings
**Epic/Stories**: US-05.4.
**Layout regions**: Top App Bar (back) → List of toggle rows (Switch): Disponibilité des favoris, Alertes de paiement, Actualités RAHETI (optional/marketing-adjacent, off by default).
**Components**: List, Switch.
**States**: standard toggle states.
**Accessibility**: standard.
**RTL**: standard mirroring.

## SCR-028 Notifications Inbox
**Epic/Stories**: US-10.3 (surfaced UI for FR-CLD-03).
**Layout regions**: Top App Bar ("Notifications") → List (one/two-line items grouped by unread/read via subtle background tint, not a separate section) → tap routes to the relevant context (e.g. a payment-confirmation notification routes to SCR-019/SCR-021).
**Components**: List, Badge (unread count, also shown on the Profile tab bottom-nav icon per [Component Library §7](../component-library.md#7-feedback--status-components)).
**States**: empty, populated, unread-present.
**Accessibility**: unread state announced per item ("Non lu: Paiement confirmé"), not conveyed by tint alone.
**RTL**: standard mirroring.

## SCR-029 Language & Theme Settings
**Epic/Stories**: US-06.1, 06.5.
**Layout regions**: Top App Bar (back) → "Langue" section: Radio list (Français / العربية / English) → "Thème" section: Segmented Button (Clair / Sombre / Système).
**Components**: List, Radio Button, Segmented Button.
**States**: selection changes apply immediately (no separate "save" step), per [User Flows §6](../user-flows.md#6-language-theme--rtl-switching-epic-06-cross-cutting) — the entire app re-renders in place, preserving navigation position.
**Accessibility**: language names are each written in their own script/language, not translated (a French speaker sees "العربية," not "Arabe," for the Arabic option) — a small but real accessibility/usability convention for language pickers.
**RTL**: this is the screen where the RTL switch itself is triggered — see [Assumptions](../assumptions-and-open-questions.md) for confirmation this screen's own layout also mirrors correctly once AR is selected (verified in the [Interactive Prototype](../interactive-prototype.md)).

## SCR-030 Sign In / Sign Up (optional)
**Epic/Stories**: US-05.1.
**Layout regions**: Top App Bar (close action) → RAHATI logo mark → Segmented Button or Tabs (Se connecter / Créer un compte) → Text Field (email or phone) → conditional OTP/password Text Field → Filled Button (primary action) → Text Button ("Continuer sans compte" — explicit guest path, honoring FR-USR-01).
**Components**: Tabs or Segmented Button, Text Field, Buttons (Filled, Text).
**States**: email-vs-phone entry, OTP-pending, error (invalid credentials — `errorContainer` inline message, not a dialog).
**Accessibility**: the guest-continuation path is never visually de-emphasized to the point of being hard to find (equal `bodyMedium` weight to the primary path's supporting text), consistent with FR-USR-01's "not required" framing.
**RTL**: standard mirroring; OTP input boxes (if used) read start-to-end per active direction.

## Completion Status
✅ All 11 screens in this group specified, including ASCII wireframes for both flagship screens (SCR-020, SCR-024).
