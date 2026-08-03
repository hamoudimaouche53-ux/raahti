# ADR-0018: Flutter Project Foundation — Structure, State Management, Routing, i18n Wiring

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Engineering team |
| **Phase** | Phase 3 — Flutter Implementation (this conversation's phase numbering) |
| **Related** | [ADR-0002](./0002-mobile-framework-selection.md), [ADR-0008](./0008-offline-first-mobile-sync.md), [ADR-0011](./0011-material-design-3-as-design-system.md), [ADR-0017](./0017-trilingual-support-fr-ar-en.md), [Repository Structure §4](../architecture/repository-structure.md#4-frontend-apps-structure-indicative-detailed-in-phase-25-8) |

## Context
Phase 3 begins Flutter implementation against the architecture fixed in Phase 1 (Clean Architecture, DDD, modular structure — [ADR-0003](./0003-backend-architecture-style.md) applied to the client) and the design system fixed in Phase 2 ([Foundations](../design/foundations.md), [Design Tokens](../../packages/design-tokens/README.md)). This ADR records the concrete engineering choices made to stand up the project foundation: folder structure, state management wiring, routing, localization, and Supabase DI — the first increment requested, before any feature screen beyond the app shell.

## Decisions

### 1. Project scaffold
`flutter create --platforms=android,ios` inside `apps/mobile` (package name `rahati`, per [PRD Assumption A1](../prd/PRD.md#14-assumptions): RAHATI for code, RAHETI for brand copy). Restricted to Android/iOS platforms only, matching [ADR-0002](./0002-mobile-framework-selection.md) — no Windows/Linux/macOS/web scaffolding was generated, since none is in scope for the mobile app surface.

### 2. Folder structure
```
lib/
  main.dart          — entry point (bootstrap + runApp)
  app.dart            — root MaterialApp.router widget
  core/                — cross-cutting foundation (mirrors SharedKernelModule/PlatformModule, Repository Structure §3)
    theme/             — design tokens ported to Dart (color, spacing, shape, motion)
    router/            — GoRouter configuration
    providers/         — Riverpod DI wiring (Supabase, theme mode, locale)
    constants/         — build-time env configuration
  l10n/                — ARB source files + generated AppLocalizations (gitignored)
  features/            — one folder per feature, added incrementally; only
                          `app_shell/` exists so far (Splash — SCR-001)
```
This is the Flutter-side equivalent of the backend's `modules/*/{domain,application,infrastructure,interface}` convention ([Repository Structure §3](../architecture/repository-structure.md#3-backend-structure-appsbackend)): each `features/<name>/` will grow `domain/`, `application/` (or `data/`), and `presentation/` sub-folders **only as populated** — `app_shell/` currently has `presentation/` only, since Splash owns no domain state, mirroring how the backend's `slatoki`/`emergency` modules skip `domain/`/`infrastructure/` for the same reason ([Module Dependency Diagram §2](../architecture/module-dependency-diagram.md#2-module-list)).

### 3. State management — Riverpod without code generation
`flutter_riverpod` is used with hand-written `Provider`/`NotifierProvider` declarations, **not** `riverpod_generator`/`build_runner`. This avoids adding a code-generation build step (and its `dev_dependencies`: `riverpod_generator`, `build_runner`, `riverpod_annotation`) before the codebase is large enough for the generator's ergonomics to outweigh that added complexity. Revisit if manual provider boilerplate becomes a measurable problem once more features land.

### 4. Routing — GoRouter, incrementally declared
A single route (`/` → `SplashScreen`) exists for now. The Phase 2 [Screen Inventory](../design/screen-inventory.md)'s 4-destination bottom-navigation shell (Map/Slatoki/Emergency/Profile) will be introduced as a `StatefulShellRoute` when the first of those screens (Map, EPIC-01) is implemented — not pre-declared with placeholder destinations now, per this phase's "no placeholder implementations" rule.

**Amended (2026-08-01, EPIC-02 US-02.1.1) — see [ADR-0024](./0024-bottom-navigation-shell-staging.md)**: the plan above (wait for all 4 destination screens to exist) turned out to be inconsistent with the Product Backlog's own V1/V1.1 release sequencing — Emergency (EPIC-03) isn't V1-scoped, so waiting for it would leave Slatoki without its required bottom-nav tab for all of V1. ADR-0024 resolves this: the full `StatefulShellRoute.indexedStack` shell is introduced now, with Emergency and Profile as explicit zero-business-logic placeholder screens rather than genuinely deferring the shell itself.

### 5. Theming — M3 `ColorScheme` + `ThemeExtension` for brand colors
[Design Tokens](../../packages/design-tokens/README.md) `color.json` is ported 1:1 into `RahatiColorTokens` (two full `ColorScheme`s). The four RAH-DOC-002 functional colors are implemented as a `ThemeExtension<RahatiFunctionalColors>` — the idiomatic Flutter mechanism for M3 custom color roles, directly implementing [ADR-0011](./0011-material-design-3-as-design-system.md)'s "extension, not replacement" rule at the code level. `spacing.json`, `shape.json`, and `motion.json` are similarly ported as typed constant classes.

**Typography — resolved (2026-07-31, before Feature 1 started)**: fonts are now bundled — static **Roboto** (Regular/Medium) for Latin, **Noto Kufi Arabic** (display/headline/titleLarge) + **Noto Naskh Arabic** (titleMedium and smaller) for Arabic, all SIL OFL-1.1 licensed. This is a deliberate, documented deviation from [Foundations §2.2](../design/foundations.md#22-font-families-assumption--see-assumptions-3)'s literal "Roboto Flex" (variable font) — full rationale in [`assets/fonts/README.md`](../../apps/mobile/assets/fonts/README.md). `RahatiTheme.resolveForLocale()` (`lib/core/theme/app_theme.dart`) swaps the Arabic pairing in at the *resolved* locale via `MaterialApp.builder`, tested in `test/core/theme/font_resolution_test.dart` and end-to-end in `test/core/localization/localization_test.dart`.

### 6. Localization — Flutter's built-in ARB/gen-l10n pipeline
`flutter_localizations` (SDK) + `intl` (pinned to `0.20.2`, the exact version `flutter_localizations` requires) + `flutter gen-l10n` (configured via `l10n.yaml`, `flutter: generate: true`), rather than a third-party i18n package — this is the official, zero-extra-runtime-dependency path, consistent with "don't introduce new dependencies unless necessary." French is the ARB template locale (`app_fr.arb`), matching RAH-DOC-005 being authored in French; `app_en.arb` and `app_ar.arb` are peers, not translations-of-template in a hierarchical sense. Generated output (`lib/l10n/app_localizations*.dart`) is gitignored — only the `.arb` sources are hand-authored/committed.

### 7. Supabase — DI-wrapped, env-driven, no hard-coded secret
`supabase_flutter` is initialized in `main()` via `bootstrapSupabase()`, using `String.fromEnvironment` (`--dart-define`) for `SUPABASE_URL`/`SUPABASE_PUBLISHABLE_KEY` (the current, non-deprecated Supabase API — `anonKey` is deprecated in `supabase_flutter` 2.16.0 in favor of `publishableKey`). **No Supabase project has been provisioned yet** ([ADR-0016](./0016-hosting-provider-selection.md) hosting decision still open) — `bootstrapSupabase()` no-ops when unconfigured, so the app boots in a backend-less mode for local UI development, CI, and tests, per [Security Architecture §4](../architecture/security-architecture.md#4-secrets-management) (no secret ever committed).

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| Riverpod with `riverpod_generator` | Less boilerplate at scale | Adds `build_runner` to the dev loop before it's justified by codebase size |
| Isar for local cache (deferred, not yet needed) | Simpler API than Drift for pure key-value/document needs | ADR-0008 already leaned toward SQL-shaped modeling matching the ERD; deferred to the first feature that needs it (Map/Discovery), not decided in this foundation-only ADR |
| Third-party i18n package (`easy_localization`, etc.) | Some convenience features (e.g. pluralization helpers) beyond ARB | Unjustified extra dependency versus Flutter's official, already-sufficient ARB pipeline |

## Consequences
### Positive
- Every token category from Phase 2 (color, spacing, shape, motion) now has a single Dart source of truth traceable back to its JSON token file, with a regression-guard test (`design_tokens_test.dart`).
- The app is fully functional, themed, and localized (FR/EN/AR with correct RTL) with zero placeholder screens beyond the one genuinely complete one (Splash).

### Negative / Trade-offs
- Real typography is now bundled (see above); a production logo asset is still not — Splash uses a placeholder mark, tracked as a design-production follow-up (not an engineering blocker).
- No local offline-cache database exists yet (correctly deferred — [ADR-0008](./0008-offline-first-mobile-sync.md) ties it to the first feature that reads cached data, not the app shell).

## Related
- [Foundations](../design/foundations.md), [Design Tokens](../../packages/design-tokens/README.md), [Screen Inventory — SCR-001](../design/screen-inventory.md), [System Architecture Document §3](../architecture/system-architecture.md#3-layered-architecture--implementation-mapping)
