# Wireframes — Web Platform (Vitrine)

| | |
|---|---|
| **Group** | Web Platform (EPIC-07) |
| **Related** | [Screen Inventory](../screen-inventory.md) · [User Flows §7](../user-flows.md#7-web-platform-epic-07) · [Responsive Layout Guidelines](../responsive-layout-guidelines.md) |

> All web screens are specified at the **Expanded** breakpoint (primary target per [Responsive Layout Guidelines §1](../responsive-layout-guidelines.md#1-window-size-classes-m3-breakpoints)); Compact/Medium behavior follows the same guideline's Navigation Adaptation table (Top App Bar + drawer) uniformly, not repeated per screen below.

---

## SCR-032 Web Landing / Mission — **FLAGSHIP**
**Epic/Stories**: US-07.1.
**Layout regions**: sticky Top App Bar (logo start-aligned, section nav — Station/Carte WC/Slatoki/App — center, language switcher + "Télécharger" Filled Button end-aligned) → hero section (mission headline `displayMedium`, supporting `bodyLarge`, illustration/photo) → mission/stats band (3–4 stat cards) → station-preview section (map thumbnail + "Voir la carte" link into SCR-033) → app-download preview band (→ SCR-035) → footer (partner contact link → SCR-036, legal links).
**Components**: Top App Bar, Buttons (Filled, Text), Card (stat cards).
**States**: standard marketing-page states (no auth-dependent content).
**Accessibility**: hero illustration has descriptive alt text; heading hierarchy is strictly sequential (`displayMedium` h1 → section `headlineMedium` h2s), not skipped for visual sizing reasons.
**RTL**: entire section order **mirrors as a block** (logo moves to end edge, nav/CTA move to start edge) — full page-level RTL, not just text alignment.

```
ASCII wireframe (flagship, expanded breakpoint):

┌───────────────────────────────────────────────┐
│ RAHETI   Station  Carte WC  Slatoki  App  🌐 [Télécharger]│
├───────────────────────────────────────────────┤
│   Une infrastructure de confort public          │
│   intelligente, partout où vous en avez besoin. │
│                          [Découvrir la carte]    │
├───────────────────────────────────────────────┤
│  [Stat] [Stat] [Stat] [Stat]                     │
├───────────────────────────────────────────────┤
│  Carte des stations (miniature)  [Voir la carte]│
├───────────────────────────────────────────────┤
│  Téléchargez l'application  [App Store][Play]    │
├───────────────────────────────────────────────┤
│ Footer: Partenaires · Mentions légales           │
└───────────────────────────────────────────────┘
```

## SCR-033 Web Station Map
**Epic/Stories**: US-07.1, 07.2.
**Layout regions**: Top App Bar (shared) → full-width interactive map (reuses the same pin/color-coding system as SCR-003) with a side filter panel (Expanded breakpoint) collapsing to an overlay sheet at Compact/Medium, per [Responsive Layout Guidelines §4](../responsive-layout-guidelines.md#4-content-layout-patterns).
**Components**: map canvas, Chip (filters), Card (place-summary side-list, expanded breakpoint only).
**States**: identical to SCR-003's states, web-adapted layout only.
**Accessibility**: same list-view alternative requirement as SCR-003.
**RTL**: side panel anchors to start edge (right in AR), map fills the remaining end-edge space.

## SCR-034 Web Slatoki Section
**Epic/Stories**: US-07.2.
**Layout regions**: Top App Bar (shared) → dedicated section header with `slatoki` accent (mirroring the mobile app's tab treatment) → explanatory content (what Slatoki is, why it matters) → embedded map filtered to Slatoki-qualified places only (reuses SCR-033's map component, pre-filtered).
**Components**: Card, map canvas (filtered), Chip.
**States**: standard.
**Accessibility**: standard heading hierarchy; magenta accent never the sole wayfinding signal (section is also textually labeled "Slatoki").
**RTL**: standard page-level mirroring.

## SCR-035 Web App Download Section
**Epic/Stories**: US-07.1, 07.2.
**Layout regions**: Top App Bar (shared) → two-column layout (Expanded): phone-mockup illustration (left/start) + download CTAs (App Store badge, Google Play badge) and a short feature-highlight list (right/end).
**Components**: Buttons (store-badge links, treated as image-buttons with accessible names, not generic M3 buttons — store badges follow each platform's own branding guidelines, not M3 styling).
**States**: standard.
**Accessibility**: store badges have accessible names ("Télécharger sur l'App Store"), not just an image with no alt text.
**RTL**: two-column layout mirrors (illustration moves to end edge, CTA column to start edge).

## SCR-036 Web Partner Contact
**Epic/Stories**: US-07.1.
**Layout regions**: Top App Bar (shared) → contact form (Text Fields: name, organization, email, message) → Filled Button "Envoyer" → alternative direct-contact info (email address, displayed as text, not only via the form).
**Components**: Text Field, Buttons (Filled).
**States**: empty, validation-error (inline per-field, `error` color + `bodySmall` message), submitted (success Snackbar/confirmation card).
**Accessibility**: every field has a visible, associated label (not placeholder-only); validation errors are announced and programmatically associated with their field.
**RTL**: form fields and labels mirror; form still reads top-to-bottom regardless of language.

## Completion Status
✅ All 5 screens in this group specified, including ASCII wireframe for the flagship screen (SCR-032).
