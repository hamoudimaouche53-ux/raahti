# ADR-0023: Explicit, Opt-In Mock Adapter for Place Detail (Cabin Status & Tariff)

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Engineering team (mock-adapter approach explicitly requested by the user for this story) |
| **Phase** | Phase 3 — Flutter Implementation, EPIC-01 closure (US-01.2.2, US-01.2.3) |
| **Related** | [ADR-0008](./0008-offline-first-mobile-sync.md), [ADR-0022](./0022-offline-cache-implementation-and-recenter-tracking.md) |

## Context
US-01.2.2 (real-time cabin Free/Occupied status, IoT-sourced) and US-01.2.3 (tariff + accepted payment methods) both depend on backend/IoT infrastructure that does not exist yet in this conversation — Phase 4 (Backend) has not started, and ADR-0016 (hosting) is still open. Every prior story in this project has handled "no backend" by showing an honest error state and stopping there. For this specific pair of stories, the user explicitly directed a different approach: build the full Flutter presentation, domain contracts, and repository interfaces for real now, backed by a clearly-labeled, explicitly opt-in mock adapter — swappable for the real one later with no UI or business-logic change — rather than leaving the feature entirely unbuilt until a backend exists.

## Decision
`PlaceDetailRepository` (domain interface) has two implementations:
- **`RestPlaceDetailRepository`** — the production default. Calls the real, already-specified endpoints (`GET /stations/{id}`, `GET /third-party-places/{id}`, docs/api/openapi.yaml). No offline cache (unlike `RestPlaceRepository`'s nearby-places cache, ADR-0008/0022) — the detail sheet is opened on demand for one place, not persistently shown while offline, so that cache's scope doesn't extend here. On failure, shows the same honest error state as every other unconfigured-backend case in this codebase.
- **`MockPlaceDetailRepository`** — an explicitly-opt-in stand-in, wired only when `AppEnv.useMockPlaceDetail` is `true` (`--dart-define=USE_MOCK_PLACE_DETAIL=true`; `false` by default, so a normal build/run/CI never sees it). Returns deterministic, fabricated cabin/status data with a realistic artificial delay (so the loading state is genuinely demonstrable too).

**The single swap point is `placeDetailRepositoryProvider`** (`lib/features/map_discovery/presentation/providers/place_detail_providers.dart`) — a one-line `if (AppEnv.useMockPlaceDetail)` branch. No other file needs to change when a real backend is deployed and the mock is retired.

**Mock data is never silently indistinguishable from real data**: three independent signals make it impossible to mistake for live/cached data —
1. The class name and doc comment (`MockPlaceDetailRepository`, extensively documented as fabricated).
2. `PlaceDetailSheet` shows a visible banner ("Données de démonstration — en attente du backend" / "Demo data — backend not yet connected") whenever `AppEnv.useMockPlaceDetail` is active, in all three languages.
3. The flag itself is a build-time constant (`bool.fromEnvironment`), not a runtime toggle a user could accidentally enable — it can only be set by whoever invokes `flutter run`/`flutter build`.

This is **narrower** than a general-purpose "demo mode": it applies only to `PlaceDetailRepository` (cabin status + tariff), not to `PlaceRepository` (the map's own nearby-places fetch, which already has a real, non-mock offline cache per ADR-0008/0022) or any other part of the app.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| Real-only repository, honest error state, no mock (the pattern used everywhere else in this codebase) | Consistent with every prior story; zero risk of mock data ever leaking into a real build | Leaves US-01.2.2/US-01.2.3 impossible to see/demo in Flutter alone until Phase 4 exists — explicitly not what the user asked for this time |
| A runtime (in-app) toggle for mock vs. real | More flexible for manual QA without rebuilding | A runtime toggle is reachable by an end user by accident in a shipped build; a build-time `--dart-define` cannot be |
| Hard-code mock data directly inside `PlaceDetailSheet` (skip the repository layer) | Fastest to write | Violates Clean Architecture boundaries this whole project has held to; would need to be deleted and rewritten (not swapped) once a backend exists — the opposite of "replaceable without changing UI/business logic" |
| A separate `MockPlaceRepository` for the map's nearby-places fetch too | Consistency with the new pattern | Not requested, and unlike detail data, the nearby-places path already has a real, meaningful offline behavior (ADR-0008/0022) — adding a second, unrelated mock path there would be scope creep |

## Consequences
### Positive
- US-01.2.2/US-01.2.3 are demonstrable end-to-end in Flutter today, with zero risk of the fabricated data reaching a real build (the flag defaults `false` and is build-time-only).
- The Domain/Data layer boundary was exercised exactly as designed: `MockPlaceDetailRepository` only had to implement the same `PlaceDetailRepository` interface `RestPlaceDetailRepository` does — no leakage into `PlaceDetailSheet` or the use cases.
- Every DTO/entity shape (`StationDetail`, `Cabin`, `ThirdPartyPlaceDetail`, `Money`) mirrors docs/api/openapi.yaml exactly, including two enum wire-format subtleties caught by unit tests: `configuration`'s French wire value (`"fixe"`, not `"fixed"`) and the snake_case values (`gas_station`, `owner_declared`) in `ThirdPartyPlaceDetail`'s enums.

### Negative / Trade-offs
- Two repository implementations to keep in sync with the domain interface going forward (minor — the interface is small and stable).
- The mock's fabricated `Place` summary field (present only for shape fidelity with the real API's `allOf` composition) is never actually rendered — a small, documented wart rather than a real UI concern, since `PlaceDetailSheet` always uses the real tapped `Place` for anything user-visible.

## Related
- `lib/features/map_discovery/domain/repositories/place_detail_repository.dart`, `data/repositories/{rest,mock}_place_detail_repository.dart`, `presentation/providers/place_detail_providers.dart`, `presentation/widgets/place_detail_sheet.dart`, `core/constants/env.dart`
- `docs/phase-3-implementation-log.md`
