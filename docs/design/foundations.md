# Foundations — Color, Typography, Iconography, Elevation, Motion, Spacing, Shape, States

| | |
|---|---|
| **Document ID** | RAH-DOC-034-FOUNDATIONS |
| **Phase** | Phase 2 — UI/UX Design System and Product Design |
| **Version** | 1.0 |
| **Related** | [Design System Specification](./design-system-specification.md) · [Design Tokens](../../packages/design-tokens/README.md) · [Assumptions](./assumptions-and-open-questions.md) |

> Values here are the **human-readable specification**; the machine-readable source of truth is [`packages/design-tokens/`](../../packages/design-tokens/README.md) (JSON). If the two ever disagree, the JSON wins and this document is out of date.

## 1. Color

### 1.1 Seed & Baseline M3 Roles
Primary seed color: **`#00677E`** (deep teal) — see [Assumptions §2](./assumptions-and-open-questions.md#2-brand-seed-color-rah-doc-002-not-supplied) for why this is provisional. M3 tonal palettes are generated algorithmically from this seed (Material Theme Builder / HCT color space); indicative tone stops:

| Role | Tone | Light hex (indicative) | Dark hex (indicative) |
|---|---|---|---|
| Primary | 40 / 80 | `#00677E` | `#5CD5F5` |
| On Primary | 100 / 20 | `#FFFFFF` | `#00363F` |
| Primary Container | 90 / 30 | `#9EEEFF` | `#004E5F` |
| On Primary Container | 10 / 90 | `#001F26` | `#9EEEFF` |
| Secondary | 40 / 80 | `#4A6267` | `#B1CBD0` |
| On Secondary | 100 / 20 | `#FFFFFF` | `#1B3438` |
| Secondary Container | 90 / 30 | `#CDE7EC` | `#324B4F` |
| On Secondary Container | 10 / 90 | `#051F23` | `#CDE7EC` |
| Tertiary | 40 / 80 | `#52606C` | `#BAC8D6` |
| On Tertiary | 100 / 20 | `#FFFFFF` | `#243138` |
| Tertiary Container | 90 / 30 | `#D5E4F2` | `#3A4750` |
| On Tertiary Container | 10 / 90 | `#0E1D27` | `#D5E4F2` |
| Error | 40 / 80 | `#BA1A1A` | `#FFB4AB` |
| On Error | 100 / 20 | `#FFFFFF` | `#690005` |
| Error Container | 90 / 30 | `#FFDAD6` | `#93000A` |
| On Error Container | 10 / 90 | `#410002` | `#FFDAD6` |
| Background / Surface | 98 / 6 | `#F5FAFB` | `#0E1416` |
| On Background / On Surface | 10 / 90 | `#171D1E` | `#DEE3E5` |
| Surface Variant | 90 / 30 | `#DBE4E6` | `#3F484A` |
| On Surface Variant | 30 / 80 | `#3F484A` | `#BFC8CA` |
| Outline | 50 / 60 | `#6F797A` | `#899393` |
| Outline Variant | 80 / 30 | `#BFC8CA` | `#3F484A` |
| Surface Container Lowest/Low/Default/High/Highest | 100→90 / 4→24 | `#FFFFFF`→`#E3E9EA` | `#090F11`→`#293032` |

### 1.2 Brand Functional Color Extension (RAH-DOC-002 §4.2, preserved per ADR-0011)
Each functional color is added as an **M3 extended color role** (own tone ramp, container/on pair) — never substituted for a baseline M3 role.

| Functional meaning | Base hex (tone 40) | Container (tone 90, light) | On-Container (tone 10, light) | Dark base (tone 80) | Dark container (tone 30) |
|---|---|---|---|---|---|
| 🟢 Free WC (`success`) | `#2E7D32` | `#C4EFC4` | `#00210A` | `#8FDB8F` | `#1E5B22` |
| 🔵 Paid WC (`info`) | `#1565C0` | `#D3E4FF` | `#001C3B` | `#A9C7FF` | `#0F4C9C` |
| 🟠 RAHETI Unit (`rahati-unit`) | `#B8860B` | `#FFE8A3` | `#271900` | `#FFCC5C` | `#8A6300` |
| 🟣 Slatoki (`slatoki`) | `#9C2896` | `#FFD6F7` | `#390036` | `#FFA6F0` | `#7A1A75` |

**Contrast rule**: every functional-color pin/badge always pairs its base color with its own `on-*` token — never with M3's baseline `on-primary`/`on-surface` — guaranteeing WCAG 2.2 AA (≥4.5:1 for text, ≥3:1 for graphical/icon elements) independent of which M3 baseline role is adjacent on screen.

### 1.3 Usage Rule
Primary/Secondary/Tertiary M3 roles style **navigation, actions, and generic UI chrome** (buttons, app bars, FABs, selected nav items). The four functional roles style **only** status-carrying elements: map pins, availability badges, cabin-status chips, Slatoki-specific accents. A component must never use a functional color as a generic accent (e.g. a "Confirm" button is never colored `slatoki-magenta` just because the screen is inside the Slatoki flow — it uses `primary`).

## 2. Typography

### 2.1 Type Scale (M3 baseline, unchanged values)
| Style | Size / Line-height | Weight | Tracking |
|---|---|---|---|
| Display Large | 57 / 64 | Regular (400) | -0.25 |
| Display Medium | 45 / 52 | Regular (400) | 0 |
| Display Small | 36 / 44 | Regular (400) | 0 |
| Headline Large | 32 / 40 | Regular (400) | 0 |
| Headline Medium | 28 / 36 | Regular (400) | 0 |
| Headline Small | 24 / 32 | Regular (400) | 0 |
| Title Large | 22 / 28 | Regular (400) | 0 |
| Title Medium | 16 / 24 | Medium (500) | 0.15 |
| Title Small | 14 / 20 | Medium (500) | 0.1 |
| Body Large | 16 / 24 | Regular (400) | 0.5 |
| Body Medium | 14 / 20 | Regular (400) | 0.25 |
| Body Small | 12 / 16 | Regular (400) | 0.4 |
| Label Large | 14 / 20 | Medium (500) | 0.1 |
| Label Medium | 12 / 16 | Medium (500) | 0.5 |
| Label Small | 11 / 16 | Medium (500) | 0.5 |

### 2.2 Font Families (assumption — see [Assumptions §3](./assumptions-and-open-questions.md#3-typography))
| Language | Family | Notes |
|---|---|---|
| FR / EN (Latin) | **Roboto Flex** (variable) | M3 reference family, native Flutter support |
| AR — display/headline sizes | **Noto Kufi Arabic** | Geometric, pairs with Roboto Flex's structure |
| AR — body/label sizes | **Noto Naskh Arabic** | Optimized legibility at small sizes |

### 2.3 Trilingual Rule
The type **scale** (size/line-height/weight steps) is identical across FR/EN/AR — only the font family and, where the Arabic family's natural cap-height differs, a ±1sp line-height compensation may be applied per size step (documented per-token in [Design Tokens](../../packages/design-tokens/README.md), not ad hoc per screen).

## 3. Iconography

- **System**: Material Symbols, **Rounded** grade, variable-weight (assumption — [Assumptions §4](./assumptions-and-open-questions.md#4-iconography)).
- **Sizes**: 18dp (dense/inline), 24dp (default, nav/app-bar/list), 36dp (emphasized/empty-state), 48dp (hero/illustration-adjacent).
- **State**: outlined (default/unselected) → filled (selected/active), matching M3's standard selected-state icon treatment (e.g. bottom-nav "Map" tab).
- **Custom icons** (bespoke, not in Material Symbols): Qibla compass needle glyph, Slatoki tent glyph, RAHETI-unit pin glyph, cabin-door-lock glyph — each drawn at the same 24dp optical size and grid as Material Symbols for visual consistency.

## 4. Elevation

| Level | dp | Use | Light surface tint | Dark shadow strategy |
|---|---|---|---|---|
| 0 | 0 | Background, filled cards at rest | none | none |
| 1 | 1 | Cards, search bar (map screen) | 5% primary tint | subtle tonal surface bump |
| 2 | 3 | Raised buttons (rare in M3), menus | 8% primary tint | tonal surface bump |
| 3 | 6 | FAB at rest, dialogs | 11% primary tint | tonal surface bump |
| 4 | 8 | FAB pressed, nav drawer | 12% primary tint | tonal surface bump |
| 5 | 12 | Bottom sheets, modal surfaces | 14% primary tint | tonal surface bump |

M3 convention followed: **dark theme uses surface-tone elevation** (lighter surface-container step per level) rather than heavier drop shadows, per M3 spec — consistent with [SRS NFR-A11Y-04](../srs/SRS.md#84-accessibility--design-system-9-new)'s dynamic-theming requirement.

## 5. Motion

### 5.1 Duration Tokens
| Token | ms | Use |
|---|---|---|
| short-1…4 | 50 / 100 / 150 / 200 | Icon toggles, small state changes (e.g. favorite-star fill) |
| medium-1…4 | 250 / 300 / 350 / 400 | Component transitions (chip selection, card expand) |
| long-1…4 | 450 / 500 / 550 / 600 | Full-screen transitions (map → place detail sheet) |
| extra-long-1…4 | 700 / 800 / 900 / 1000 | Complex, multi-element choreography (QR-scan → unlock confirmation sequence) |

### 5.2 Easing Tokens
| Token | Cubic-bezier | Use |
|---|---|---|
| emphasized | `(0.2, 0.0, 0, 1.0)` | Primary screen transitions |
| emphasized-decelerate | `(0.05, 0.7, 0.1, 1.0)` | Elements entering the screen |
| emphasized-accelerate | `(0.3, 0.0, 0.8, 0.15)` | Elements exiting the screen |
| standard | `(0.2, 0.0, 0, 1.0)` | Default component motion |
| standard-decelerate | `(0, 0, 0, 1)` | Simple entrances |
| standard-accelerate | `(0.3, 0, 1, 1)` | Simple exits |

### 5.3 Reduced-Motion Rule (WCAG 2.2 AA / platform accessibility)
Every motion token above has a reduced-motion fallback (cross-fade only, `short-2` duration) applied automatically when the OS-level "reduce motion" accessibility setting is on — a hard requirement, not optional, per [SRS NFR-A11Y-02](../srs/SRS.md#84-accessibility--design-system-9-new).

## 6. Spacing (8dp grid, per this phase's explicit instruction)

| Token | Value | Typical use |
|---|---|---|
| `space-0` | 0dp | — |
| `space-1` | 4dp | Icon-to-label gap, dense list internal padding |
| `space-2` | 8dp | Base unit — chip padding, small gaps |
| `space-3` | 12dp | Compact card padding |
| `space-4` | 16dp | Standard screen margin, card padding |
| `space-5` | 20dp | Section internal spacing |
| `space-6` | 24dp | Section-to-section spacing |
| `space-8` | 32dp | Large section breaks |
| `space-10` | 40dp | — |
| `space-12` | 48dp | Empty-state illustration spacing |
| `space-16` | 64dp | Top-level screen vertical rhythm on tablet/desktop breakpoints |

4dp (`space-1`) is the only permitted half-step below the 8dp rhythm, reserved for icon/label micro-alignment — never used for macro layout spacing.

## 7. Shape

| Token | Corner radius | Use |
|---|---|---|
| `shape-none` | 0dp | Full-bleed images, map |
| `shape-extra-small` | 4dp | Chips (dense) |
| `shape-small` | 8dp | Buttons, text fields |
| `shape-medium` | 12dp | Cards |
| `shape-large` | 16dp | Dialogs |
| `shape-extra-large` | 28dp | Bottom sheets (top corners only), FAB |
| `shape-full` | 9999dp (pill) | Chips (default), badges |

## 8. Interaction States

M3 standard state-layer opacities, applied over the component's base color:

| State | Opacity |
|---|---|
| Hover | 8% |
| Focus | 10% (12% for text/icon-only targets) |
| Pressed | 10% (12% for text/icon-only targets) |
| Dragged | 16% |
| Disabled content | 38% |
| Disabled container | 12% |

**Focus visibility rule (WCAG 2.2 AA, new success criterion 2.4.11)**: every focusable element's focus indicator has a minimum 2px outline with ≥3:1 contrast against its background, not obscured by any other element when focused — checked explicitly in the [Component Library](./component-library.md) spec per component.

## 9. Completion Status

| Item | Status |
|---|---|
| Color: M3 baseline roles + 4 brand functional extensions, light/dark | ✅ Complete (seed color provisional, see Assumptions) |
| Typography: full M3 scale + trilingual family pairing | ✅ Complete (family pairing provisional, see Assumptions) |
| Iconography: system, sizes, states, custom icon list | ✅ Complete |
| Elevation: 6 levels, light/dark strategy | ✅ Complete |
| Motion: duration + easing tokens, reduced-motion rule | ✅ Complete |
| Spacing: 8dp grid | ✅ Complete |
| Shape: corner-radius scale | ✅ Complete |
| Interaction states + focus-visibility rule | ✅ Complete |

**Phase 2 deliverable 2 of 10 — Foundations: COMPLETE.**
