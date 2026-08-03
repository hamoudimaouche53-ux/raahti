# ADR-0022: Offline Cache Implementation (Drift) and Continuous Position Tracking

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Engineering team |
| **Phase** | Phase 3 — Flutter Implementation, EPIC-01 close-out (US-01.1.6, US-01.1.7) |
| **Related** | [ADR-0008 — Offline-first strategy](./0008-offline-first-mobile-sync.md), [ADR-0020 — Custom marker clustering](./0020-custom-marker-clustering.md) |

## Context
ADR-0008 accepted the offline-first **strategy** (local read cache, freshness indicator, no offline writes) but left the local cache **technology** an open "Drift vs. Isar" question, and left the sync-refresh/retry mechanics unspecified. Closing out EPIC-01 requires both US-01.1.6 (recenter, FR-MAP-06's "position tracking" with lock/unlock) and US-01.1.7 (offline cache, FR-MAP-07) fully implemented, not deferred further.

## Decision

### 1. Local cache: Drift (not Isar)
Drift (SQLite-backed, code-generated, `drift`/`drift_dev`/`sqlite3`/`path_provider`) was chosen over Isar. `sqlite3_flutter_libs` was evaluated and **not** added — its own changelog deprecates it as of `sqlite3` package v3.x ("no longer necessary… this version removes all code from this package"), which is exactly the resolved version here; the plain `sqlite3` + `drift` combination is sufficient. Schema: a single `CachedPlaces` table (one row per place, whole-replace on every successful fetch — never merged/accumulated) plus a single-row `CacheMeta` table holding `lastSyncedAt`. `PlaceLocalDataSource` is the only class that touches Drift directly; `RestPlaceRepository` depends on it exactly like it depends on `PlaceRemoteDataSource`, keeping the Domain layer (`PlaceRepository`, `PlacesSnapshot`) storage-agnostic.

### 2. Fallback + retry mechanics live in the Data/Presentation layers, not a new backend concept
- **`RestPlaceRepository`**: on every `getNearbyPlaces()` call, try the remote fetch first; on success, write the cache and return `PlacesSnapshot(isFromCache: false)`; on a `PlaceRepositoryFailure`, read the cache and return it with `isFromCache: true` — only rethrowing the original failure if the cache itself is empty (nothing usable to show at all).
- **`NearbyPlacesNotifier`** (an `AsyncNotifier`, replacing the former plain `FutureProvider`): when a result comes back `isFromCache: true`, it schedules a background retry (`Timer`, 20s interval) that keeps re-attempting silently — visible to the UI only via `isReconnectingNearbyPlacesProvider` (drives SCR-031's "reconnecting" inline spinner) — until a fetch succeeds, at which point the map updates automatically. No manual "retry" button exists or is needed.
- **No `connectivity_plus` (or any OS-level connectivity package) was added.** "Offline" is inferred purely from whether the most recent fetch attempt failed, which is sufficient for this screen's actual need (decide what to render) and avoids a dependency whose signal (`ConnectivityResult`) doesn't itself guarantee backend reachability anyway — a device can report "connected to Wi-Fi" while the backend is unreachable, so fetch-outcome is the more accurate signal for this specific decision.

### 3. Continuous position tracking is a real GPS stream, not a re-labeled one-shot fetch
FR-MAP-06 says "position **tracking**," and a lock/unlock toggle over a value that only ever resolves once (the existing one-shot `userPositionProvider`, kept for the nearby-places query center) would have nothing ongoing to lock or unlock — implementing it that way would itself be the kind of placeholder this phase's rules forbid. `DeviceLocationDataSource.watchPosition()` (new, alongside the existing `getCurrentPosition()`) wraps `Geolocator.getPositionStream()`; a new `userPositionStreamProvider` (`StreamProvider`, separate from the one-shot `userPositionProvider`) drives the live blue-dot marker and the recenter FAB's camera-follow. The two providers are deliberately kept separate so a live position tick never re-triggers the nearby-places query.

### 4. Smooth camera animation is hand-rolled, not a new `flutter_map` plugin
Same rationale as ADR-0020: `MapController.move()` is an instant jump with no built-in animation, and adding an external animated-map-controller package risks the same `latlong2` version-pinning dead end that ruled out clustering plugins. `_animateCameraTo()` (`MapScreen`) interpolates center/zoom via a plain `AnimationController` + `CurvedAnimation` (M3 `standard` easing, `medium4`/400ms duration from the existing motion tokens), calling `MapController.move()` once per tick — reused for both the recenter FAB and cluster-tap zoom, so both are consistently smooth now.

### 5. Lock/unlock semantics: tap-to-lock-and-recenter, pan-to-unlock
Matches the established "my location" FAB convention (Google Maps, Uber): tapping the FAB always re-locks and animates to the current position; any user-initiated pan/zoom gesture unlocks it (so the app never fights a user who's deliberately looking elsewhere). The FAB's locked/unlocked state is conveyed by **icon** (`gps_fixed` vs. `gps_not_fixed`) plus a distinct M3 color role (`primary` vs. `primaryContainer`), not color alone, per the project's standing WCAG 2.2 AA "no information by color alone" rule.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| Drift (chosen) | Actively maintained, code-generated type safety, plain SQLite (portable, inspectable), no `sqlite3_flutter_libs` needed at the resolved `sqlite3` version | Requires `build_runner` codegen step |
| Isar | Also viable, NoSQL-style, no SQL needed | Historically slower-cadence maintenance releases than Drift; SQL's inspectability was preferred for a cache that's explicitly meant to be simple/replaceable, not a long-term embedded database |
| `connectivity_plus` for offline detection | Standard, widely used | Doesn't guarantee backend reachability (Wi-Fi-connected ≠ backend-reachable); fetch-outcome is strictly more accurate for this decision and needed no new dependency |
| Queue/retry with exponential backoff | More sophisticated resilience | Not warranted at this data volume/criticality (a read-only, non-urgent background refresh); a fixed 20s interval is simple, predictable, and easy to reason about/test (`NearbyPlacesNotifier.retryInterval` is a named constant, not a magic number) |
| A third-party animated-map-controller package | Less code to write | Same `latlong2` pinning risk as ADR-0020's clustering plugins; ~30 lines of hand-rolled tweening is cheap by comparison |

## Consequences
### Positive
- ADR-0008's open "Drift vs. Isar" question is resolved — Phase 3's local-cache technology is no longer indicative/pending.
- The offline experience is genuinely self-healing (automatic background retry + recovery), not just a static "you're offline" message.
- `PlacesSnapshot` gives the UI everything FR-MAP-07 asks for (data + freshness + provenance) as one cohesive domain type, rather than three loosely-related signals threaded separately through the provider graph.

### Negative / Trade-offs
- Two position providers (`userPositionProvider` one-shot, `userPositionStreamProvider` continuous) is slightly more surface area than one — accepted deliberately to avoid re-querying nearby places on every GPS tick (see Decision §3).
- The fixed 20s retry interval means recovery isn't instantaneous after connectivity actually returns — acceptable for a background, non-blocking refresh; not tunable via remote config today (no such mechanism exists yet in this codebase).
- `sqlite3`'s native-asset build step adds to Android build time; not measured as a practical issue on the reference device in this phase.

## Related
- `lib/features/map_discovery/data/local/`, `data/datasources/place_local_data_source.dart`, `data/repositories/rest_place_repository.dart`, `presentation/providers/place_providers.dart`, `presentation/widgets/recenter_fab.dart`, `presentation/screens/map_screen.dart`
- `docs/phase-3-implementation-log.md`
