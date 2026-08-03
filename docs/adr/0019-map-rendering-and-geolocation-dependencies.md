# ADR-0019: Map Rendering, Geolocation, and REST Client Dependencies (Feature 1 — Real-Time Map)

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Engineering team |
| **Phase** | Phase 3 — Flutter Implementation, Feature 1 (EPIC-01 / US-01.1.1) |
| **Related** | [ADR-0007 — REST](./0007-api-style-rest.md), [ADR-0016 — Hosting (open)](./0016-hosting-provider-selection.md), [openapi.yaml — GET /places/nearby](../api/openapi.yaml), [Screen Inventory — SCR-003](../design/screen-inventory.md) |

## Context
FR-MAP-01 (US-01.1.1) requires displaying the user's live position and nearby places on a map. Neither Phase 1 (System Architecture) nor Phase 2 (Design System) fixed a map-rendering SDK, a geolocation package, or an HTTP client — these are mobile-implementation-level choices with no prior ADR. Per this phase's explicit instruction, each is justified here **before** being added to `pubspec.yaml`.

## Decisions

### 1. Map rendering — `flutter_map` (+ `latlong2`), not `google_maps_flutter`
- **Why not Google Maps**: `google_maps_flutter` requires a billing-enabled Google Cloud API key. No hosting/cloud vendor decision has been made yet ([ADR-0016](./0016-hosting-provider-selection.md) is still open/Proposed), and introducing a paid, credential-gated dependency this early would both block this feature entirely (no key exists) and prematurely commit to a vendor before that decision is authorized.
- **Why `flutter_map`**: open-source (BSD-3), no API key required to render tiles, renders against any standard XYZ/WMTS tile source — so it is not itself a long-term vendor lock-in; swapping the tile provider later (or migrating to `google_maps_flutter` if a future decision picks Google Cloud) does not require touching the Domain or Data layers, only the `MapScreen`'s tile-layer configuration.
- **Tile source (development-only)**: OpenStreetMap's public demo tile server (`tile.openstreetmap.org`), used with the required `User-Agent` header per OSM's tile usage policy. **This is explicitly not production-appropriate** (OSM's policy disallows heavy/production traffic against the demo server) — tracked as a follow-up: select a production tile provider (Mapbox, Stadia Maps, MapTiler, or a self-hosted tile server) before this feature ships, likely bundled with the eventual hosting-provider decision.
- **`latlong2`**: `flutter_map`'s own required companion package for its `LatLng` type — not an independent choice.

### 2. Geolocation — `geolocator`
The Flutter SDK has no built-in cross-platform device-location API. `geolocator` (Baseflow) is the de facto standard package for this (permission request/check, current position, position stream), actively maintained, used by a large share of production Flutter apps. No `permission_handler` dependency was added alongside it — `geolocator` exposes its own `checkPermission()`/`requestPermission()` API sufficient for the single permission (location) this feature needs, so a second permissions package would be redundant.

### 3. REST client — `http`
[ADR-0007](./0007-api-style-rest.md) fixed REST as the API style; the mobile app must call the backend (`GET /v1/places/nearby` per [openapi.yaml](../api/openapi.yaml)) rather than querying Supabase tables directly, per [Architecture Overview §1](../architecture/architecture-overview.md#1-vue-densemble-de-la-plateforme)'s "no client talks to the database directly" rule. `http` is the official Dart-team-maintained package — the lightest-weight option that fully covers this feature's needs (a single unauthenticated `GET` with query parameters). `dio` (a heavier, more feature-rich alternative with interceptors/retry/etc.) is not justified yet; revisit if/when the API layer needs interceptor-based concerns (auth token refresh, request logging) that `http` cannot express cleanly.

## Consequences
### Positive
- Zero new paid/credentialed dependencies — consistent with the project's existing pattern of deferring vendor lock-in until a decision is authorized (payment provider, hosting provider).
- The Domain layer (`Place`, `Coordinates`, `PlaceRepository`) has no dependency on any of these three packages — they are confined to the Presentation layer (`flutter_map`, `geolocator`) and the Data layer (`http`), preserving the Clean Architecture dependency rule.

### Negative / Trade-offs
- OSM's demo tile server is not production-ready (rate limits, policy restrictions) — a real blocker, tracked in the Phase 3 implementation log, not silently deferred.
- `flutter_map`'s visual polish and feature set (offline tile caching, vector tiles, 3D) is more limited than Google Maps' — acceptable at this stage given no backend/hosting exists yet to make that trade-off consequential.

## Related
- [Phase 3 Implementation Log — Feature 1](../phase-3-implementation-log.md)
