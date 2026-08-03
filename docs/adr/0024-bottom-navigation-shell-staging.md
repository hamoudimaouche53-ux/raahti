# ADR-0024: Bottom Navigation Shell Staging — Full 4-Tab Shell Now, Emergency as a Zero-Logic Placeholder

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-08-01 |
| **Deciders** | Product owner (explicit decision) + Engineering team |
| **Phase** | Phase 3 — Flutter Implementation, EPIC-02 US-02.1.1 |
| **Related** | [ADR-0018 — Flutter project foundation](./0018-flutter-project-foundation.md), [docs/design/component-library.md §5](../design/component-library.md#5-navigation), [docs/backlog/product-backlog.md](../backlog/product-backlog.md) |

## Context
`lib/core/router/app_router.dart`'s original doc comment (written during Feature 0/1 of EPIC-01) deferred the `StatefulShellRoute` bottom-navigation shell "until Slatoki/Emergency/Profile exist." That was written before the Product Backlog's Release Alignment table was finalized. Re-checking it now, ahead of EPIC-02:

- `docs/design/component-library.md §5` mandates the Bottom Navigation Bar have **exactly 4 destinations, fixed order — Map / Slatoki / Emergency / Profile** — never fewer, never more (RAH-DOC-005 §2.3).
- **US-02.1.1** (EPIC-02, V1-scoped): "a dedicated Slatoki tab in the bottom nav, distinct from the general map" — requires the bottom nav to exist now.
- Per the Release Alignment table, **EPIC-03 (Mode Urgence)** is scheduled for **V1.1**, not V1. It will not be implemented before EPIC-02 ships.
- EPIC-05 (User Profile & Account) is partially V1-scoped (US-05.1/05.2/05.4) but has not been implemented yet either — it comes after EPIC-02 in the approved sequencing.

Read literally, the original comment would mean Slatoki has no bottom-nav tab for the entire V1 release, which directly contradicts FR-SLK-01/US-02.1.1. This is a genuine sequencing conflict between the existing implementation-plan comment and the Release Alignment table, not a technical judgment call — escalated to the product owner rather than resolved unilaterally (unlike ADR-0019 through ADR-0023, which were each pure technology choices).

## Decision
Build the **full 4-tab `StatefulShellRoute` now**, as part of US-02.1.1:

1. **Tab order is fixed from the start**: Map, Slatoki, Emergency, Profile — matching RAH-DOC-005 §2.3 and never reordered by locale (component library §5: destination order does not mirror in RTL, only each item's internal icon+label layout does).
2. **Emergency's destination renders a minimal placeholder screen** (`EmergencyPlaceholderScreen`) — a themed, localized, accessible `Scaffold` stating the feature is "Coming in V1.1." It contains **zero business logic**: no fake emergency flow, no mocked facility lookup, no discount calculation — nothing EPIC-03 will need to un-fake later. It participates fully in theming (light/dark), localization (FR/EN/AR), and accessibility (a real `Semantics` label, not an empty screen a screen reader announces as blank) like every other screen in this codebase.
3. **Profile's destination renders an equivalent placeholder** (`ProfilePlaceholderScreen`), by the same reasoning — EPIC-05 has not been approved for implementation in this pass ("Proceed with EPIC-02" was the explicit instruction), so building any real Profile business logic now would be scope invention exactly as forbidden by this phase's rules. This extends the product owner's Emergency-placeholder decision symmetrically to Profile, since the same "not yet in scope, don't fake it" reasoning applies to both tabs equally.
4. **Placeholders are structurally swappable, not structurally coupled**: each placeholder is addressed by its own stable route path (`/emergency`, `/profile`) inside its own `StatefulShellBranch`. When EPIC-03/EPIC-05 are implemented, their real screens replace the placeholder widget at that route with no change to `AppRoutePaths`, the shell's branch structure, or any other screen's navigation code.
5. **`IndexedStack`-backed branches** (`StatefulShellRoute.indexedStack`) so each tab's navigation state and scroll position persist when switching tabs — the standard GoRouter pattern for this exact requirement, not a custom implementation.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| Full 4-tab shell now, Emergency + Profile as zero-logic placeholders (chosen) | Matches the spec's "exactly 4, fixed order" from day one; no nav-bar reshuffling later; each placeholder is honest about its own status, not disguised | Two screens temporarily show "coming soon" — acceptable since neither fabricates functionality, and both are labeled to what they are |
| Growing shell: 2 tabs now (Map, Slatoki), add Profile then Emergency as their epics land | No placeholder screens at all | Nav bar shape changes twice more during V1/V1.1; briefly violates the "exactly 4, fixed order" spec while only 2–3 tabs exist; more rework (`StatefulShellRoute` config, its tests, and the M3 `NavigationBar` widget all get touched three separate times instead of once) |
| Build the real EPIC-03/EPIC-05 screens now, out of sequence | Zero placeholders anywhere | Directly contradicts "Implement one User Story at a time" and this pass's explicit "Proceed with EPIC-02" scope; would mean inventing Emergency/Profile business logic without their own backlog stories, ADRs, or traceability review |

## Consequences
### Positive
- FR-SLK-01/US-02.1.1 is satisfied to the letter: Slatoki has its own bottom-nav tab, distinct from Map, from the moment EPIC-02 ships.
- The bottom nav's shape (4 fixed destinations, fixed order) is correct for the rest of V1 and V1.1 — no later refactor of the shell itself, only of what each branch's *screen* renders.
- Neither placeholder introduces anything EPIC-03 or EPIC-05 will need to remove or rewrite — swapping them out is a one-file change (replace the branch's screen widget) with no router/shell/test-harness impact.

### Negative / Trade-offs
- Two tabs are visibly non-functional in the shipped V1 build until their epics land — mitigated by making that state explicit and localized ("Coming in V1.1" / equivalent for Profile) rather than a broken or empty-looking tab.
- `MapScreen`'s own doc comment ("Persistent bottom navigation — deferred until Slatoki/Emergency/Profile exist") is now stale and is corrected as part of this story (see Files Modified in the Phase 3 implementation log).

## Related
- `lib/core/router/app_router.dart`, `lib/features/app_shell/presentation/widgets/rahati_nav_shell.dart`, `lib/features/emergency/presentation/screens/emergency_placeholder_screen.dart`, `lib/features/profile/presentation/screens/profile_placeholder_screen.dart`, `lib/features/slatoki/presentation/screens/slatoki_screen.dart`
- `docs/phase-3-implementation-log.md`
