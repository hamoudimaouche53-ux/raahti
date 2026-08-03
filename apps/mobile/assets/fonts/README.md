# Bundled Fonts

Resolves the typography blocker flagged in [ADR-0018](../../../../docs/adr/0018-flutter-project-foundation.md)
and [Foundations §2.2](../../../../docs/design/foundations.md#22-font-families-assumption--see-assumptions-3).

| Family (pubspec) | Weight | File | Google Fonts version |
|---|---|---|---|
| `Roboto` | 400 Regular | `Roboto-Regular.ttf` | v51 |
| `Roboto` | 500 Medium | `Roboto-Medium.ttf` | v51 |
| `Noto Kufi Arabic` | 400 Regular | `NotoKufiArabic-Regular.ttf` | v27 |
| `Noto Kufi Arabic` | 500 Medium | `NotoKufiArabic-Medium.ttf` | v27 |
| `Noto Naskh Arabic` | 400 Regular | `NotoNaskhArabic-Regular.ttf` | v44 |
| `Noto Naskh Arabic` | 500 Medium | `NotoNaskhArabic-Medium.ttf` | v44 |

Downloaded from `fonts.gstatic.com` via the Google Fonts API (`fonts.google.com/download/list?family=...`). License: **SIL Open Font License 1.1** for all six files — see [`OFL.txt`](./OFL.txt). Freely bundleable and redistributable with the application per the license terms (condition 1: not sold by themselves — not applicable here).

## Deviation from Foundations §2.2 (documented, not silent)

[Foundations §2.2](../../../../docs/design/foundations.md#22-font-families-assumption--see-assumptions-3) specifies **Roboto Flex** (a variable font). This bundle uses **static Roboto** (Regular + Medium only) instead. Rationale, recorded in [ADR-0018](../../../../docs/adr/0018-flutter-project-foundation.md):

- The M3 type scale ([Design Tokens](../../../../packages/design-tokens/typography.json)) only ever uses weights 400 and 500 — none of Roboto Flex's variable axes (width, optical size, grade, etc.) are exercised by any approved screen.
- Static Roboto at those two weights is visually indistinguishable from Roboto Flex rendered at the same weight/width/optical-size defaults.
- Bundling 2 static files (~160KB each) is significantly lighter than the Roboto Flex variable font (~1.5–2MB) and avoids registering variable-font axis metadata in `pubspec.yaml`, which Flutter's font loader supports but adds complexity not yet justified.
- If a future screen needs Roboto Flex's variable capabilities (e.g. an animated weight transition), this is a straightforward addition — swap the two static files for the variable one and update the `fonts:` entry, no application code changes needed since consumers reference the family name `"Roboto"`, not specific files.

## Usage

Applied in [`lib/core/theme/app_theme.dart`](../../lib/core/theme/app_theme.dart) via `ThemeData.fontFamily`/`fontFamilyFallback`, resolved per-locale (Latin → Roboto; Arabic → Noto Kufi Arabic for display/headline styles, Noto Naskh Arabic for body/label styles, per [Foundations §2.2](../../../../docs/design/foundations.md#22-font-families-assumption--see-assumptions-3)).
