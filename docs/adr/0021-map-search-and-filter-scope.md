# ADR-0021: Map Search & Filter Scope — Client-Side, FR-MAP-05-Only Categories, No Speculative Filters

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Engineering team |
| **Phase** | Phase 3 — Flutter Implementation, EPIC-01 US-01.1.4 / US-01.1.5 |
| **Related** | [ADR-0020 — Custom marker clustering](./0020-custom-marker-clustering.md), [ADR-0019 — Map rendering dependencies](./0019-map-rendering-and-geolocation-dependencies.md) |

## Context
The Phase 3 instruction for this story asked for full-text search with debouncing, category filters, a distance filter, an accessibility filter "if defined in the specification", and an availability/open-now filter "only if defined in the approved requirements" — explicitly gating the last two on whether the approved spec actually defines them, to avoid inventing scope.

Checking RAH-DOC-005/SRS/backlog/wireframes:
- **FR-MAP-04** (`docs/srs/SRS.md`): bilingual search bar with nearby-place suggestions.
- **FR-MAP-05**: multi-select quick filter chips — **exactly** "All / Free WC / Paid WC / RAHETI Units / Slatoki". No accessibility or open-now chip is listed.
- **SCR-003** wireframe (`docs/design/wireframes/mobile-map-discovery.md`): Search Bar + one horizontal Filter Chip row above the map. No distance-selector region is drawn.
- **SCR-005/006**: PMR ("accessible") and Open/Closed appear only as **place-detail tag chips** on the detail sheet — never as a map-level filter anywhere in RAH-DOC-005, the SRS, the backlog, or the wireframes.
- `docs/api/openapi.yaml`'s `GET /places/nearby` already defines `q` (free-text search) and repeatable `type[]` (FR-MAP-05's five values) as approved query parameters — plus a `radiusMeters` parameter (already used for the base "nearby" query, not exposed as a user-facing filter before this story).

## Decision
1. **Accessibility (PMR) and open-now/availability filters are *not* implemented as map filters.** Neither is defined anywhere as a *filter* — only as a `Place.tags` value shown on the detail sheet (US-01.2.x). Per the instruction's own "if/only if defined in the specification" qualifier, inventing a filter chip for them would be scope invention, not spec compliance. `PlaceCategory` therefore has exactly the four FR-MAP-05 values (`free`, `paid`, `rahatiUnit`, `slatoki`) plus the pre-existing "Tout" (all) clear state.
2. **A distance filter is implemented**, layered onto the `radiusMeters` API parameter that RAH-DOC-005/openapi.yaml already approved (Phase 1) — not a new concept, just newly surfaced in the UI. To avoid adding a wireframe region SCR-003 doesn't show, it renders as two additional chips (`< 1 km`, `< 5 km`) in the *same* scrollable Filter Chip row FR-MAP-05 already specifies, using the same M3 Chip component — no new UI region.
3. **Filtering is entirely client-side**, applied to the already-fetched `nearbyPlacesProvider` result via a pure `filterPlaces()` domain function (mirrors `clusterPlaces()`, ADR-0020) — not a new network request per filter change. `PlaceRemoteDataSource`/`PlaceRepository` are unchanged this story; the data layer is already positioned for a future server-side `q`/`type[]` pass (both already in the OpenAPI contract) without changing `PlaceFilter`'s shape or any call site above the repository boundary.
4. **Search matches all three `LocalizedText` languages** (fr/ar/en) regardless of the active UI locale, not just the displayed one — a more forgiving match than FR-MAP-04's minimum ("bilingual FR/AR") requires.
5. **Debouncing lives in the presentation widget** (`MapSearchBar`'s own `Timer`), not in Riverpod state — `PlaceFilterNotifier` only ever holds the settled value, so `MapScreen` never rebuilds mid-keystroke.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| Client-side `filterPlaces()` over the fetched list (chosen) | No extra network round-trip per filter change; instant; keeps `_mapController` untouched; trivial to unit test | Filters only what was already fetched within the base `nearbyPlacesProvider` radius — acceptable since that radius already exceeds any of the new `< 1 km`/`< 5 km` distance caps |
| Re-query `GET /places/nearby` with `q`/`type[]`/`radiusMeters` on every filter change | Would scale to server-side result sets larger than one fetch | No backend is deployed yet (ADR-0016 still open); adds latency to every keystroke/chip tap for no present benefit; the client-side pass already satisfies "prepare the data layer for minimal-change backend swap" since only the data layer would need to change later, not `PlaceFilter`/`filterPlaces`'s call sites |
| Implement PMR/open-now as map filters anyway (since the data — `Place.tags` — already exists) | Technically easy, data is already there | Directly contradicts the instruction's explicit "if/only if defined in the specification" gate; FR-MAP-05 enumerates its five chips exhaustively, so adding two more silently changes an approved requirement rather than implementing it |
| A dedicated distance-selector UI region (slider/dropdown) instead of chips | More conventional for a numeric range | Adds a wireframe region SCR-003 doesn't define; chips reuse an already-approved component and layout position with zero new design surface |

## Consequences
### Positive
- FR-MAP-05 is implemented to the letter — no silent scope drift on the category set.
- The distance filter is grounded in an already-approved API parameter, not a new backend concept, while still respecting the wireframe's single-chip-row layout.
- `filterPlaces()` is a pure, dependency-free function — unit-tested independently of Riverpod/Flutter, same testing discipline as `clusterPlaces()` (ADR-0020).
- Filtering never calls `_mapController.move()`, so the camera position is preserved by construction, not by a special-cased guard.

### Negative / Trade-offs
- The distance chips cap results to what a single `nearbyPlacesProvider` fetch already returned — if a future default fetch radius is smaller than a user's selected distance cap, that cap would have no additional effect. Not an issue today (no backend is deployed to observe an actual default radius), but worth revisiting once ADR-0016's hosting decision lands and a real default radius is chosen.
- PMR and open-now remain unavailable as map filters until a future story adds them to an approved spec revision (SRS/backlog/wireframe) — flagged, not silently dropped.

## Related
- `lib/features/map_discovery/domain/entities/place_filter.dart`, `domain/usecases/filter_places.dart`, `presentation/providers/place_filter_provider.dart`, `presentation/widgets/map_search_bar.dart`, `presentation/widgets/map_filter_chips.dart`
- `docs/phase-3-implementation-log.md`
