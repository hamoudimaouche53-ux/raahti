# ADR-0020: Custom Marker Clustering (No Compatible Plugin)

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Engineering team |
| **Phase** | Phase 3 — Flutter Implementation, EPIC-01 US-01.1.2 |
| **Related** | [ADR-0019 — Map rendering dependencies](./0019-map-rendering-and-geolocation-dependencies.md) |

## Context
US-01.1.2 requires marker clustering ("support clustering when appropriate"). Every clustering package on pub.dev compatible with `flutter_map` (`flutter_map_marker_cluster`, `flutter_map_marker_cluster_plus`, `flutter_map_marker_cluster_2`, `flutter_map_supercluster`) is pinned to `latlong2 ^0.8.x`/`^0.9.x`. This project already resolves `latlong2 ^0.10.1` transitively through `flutter_map 8.3.1` (ADR-0019, accepted and already integrated/tested/screenshotted in Feature 1). `flutter pub add` was attempted for all four candidates; all four fail dependency resolution.

## Decision
Implement clustering as a hand-rolled, pure Dart function (`clusterPlaces()`, `lib/features/map_discovery/presentation/clustering/place_clusterer.dart`) rather than adding a dependency:
- **Algorithm**: greedy single-link clustering. A "seed" place absorbs any other place within a fixed pixel radius (60px), converted to meters via the standard Web Mercator meters-per-pixel formula at the current zoom and a reference latitude. This makes clustering self-adjusting: the same pixel radius covers many kilometers when zoomed out and meters when zoomed in, so clusters dissolve into individual markers as the user zooms in.
- **Rendering**: `ClusterMarker` (M3 `secondaryContainer`/`onSecondaryContainer` — generic chrome, not a functional status color, per Foundations §1.3's usage rule) shows the member count; tapping it zooms the camera in by 2 levels centered on the cluster centroid.
- **Testability**: `clusterPlaces()` is a pure function with no Flutter/`flutter_map` dependency, making it directly unit-testable (`place_clusterer_test.dart`) without any widget rendering or viewport concerns.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| Hand-rolled clusterer (chosen) | No new dependency; fully unit-testable; full control over M3 styling | Not hierarchical/supercluster-grade — O(n²) worst case, acceptable for a "nearby places" query's scale, not a whole-country dataset |
| Downgrade `flutter_map`/`latlong2` to satisfy a plugin | Would work with an existing plugin | Undoes Feature 1's working, tested, device-screenshotted `flutter_map 8.3.1` integration — directly conflicts with this phase's "keep the application runnable after every completed story" rule |
| Fork/patch a clustering plugin to bump its `latlong2` constraint | Reuses more plugin logic (viewport culling, animation) | Forking a third-party package to fix a dependency pin is higher-maintenance than ~90 lines of pure Dart, and still needs vetting/testing regardless |

## Consequences
### Positive
- Zero new runtime dependencies for this story.
- Clustering logic is deterministically unit-tested (7 test cases covering empty input, single place, same-position clustering, distance-threshold behavior at different zooms, and centroid computation) independent of `flutter_map`'s rendering/viewport behavior — which a plugin's black-box clustering would not have afforded as cleanly.

### Negative / Trade-offs
- No built-in animation between clustered/unclustered states (most plugins offer this); acceptable at V1, revisit if it becomes a product requirement.
- Greedy single-link clustering can occasionally produce a slightly larger-than-ideal cluster radius in dense areas (a place near a cluster's edge may pull in a place just outside the "true" pairwise radius via chaining) — a known trade-off of single-link clustering, not a bug; acceptable given the "nearby places" data volumes this app handles.

## Related
- `lib/features/map_discovery/presentation/clustering/`, `docs/phase-3-implementation-log.md`
