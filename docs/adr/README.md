# Architecture Decision Records — Index

| | |
|---|---|
| **Document ID** | RAH-DOC-016-ADR-INDEX |
| **Phase** | Phase 0 — Analysis (extended in Phase 1 — System Architecture) |
| **Format** | Lightweight MADR (Markdown Any Decision Records) |
| **Related** | [Architecture Overview](../architecture/architecture-overview.md) · [System Architecture Document](../architecture/system-architecture.md) · [Template](./template.md) |

ADRs record decisions that **operationalize** RAH-DOC-005's indicative architecture (§7) or add constraints communicated after it (e.g. Material Design 3, Phase 1 instructions). None reinterpret or override a stated (non-indicative) requirement — see [ADR-0001](./0001-rah-doc-005-as-single-source-of-truth.md) for the governing rule.

### Phase 0

| ID | Title | Status |
|---|---|---|
| [0001](./0001-rah-doc-005-as-single-source-of-truth.md) | RAH-DOC-005 as the Functional Single Source of Truth | Accepted |
| [0002](./0002-mobile-framework-selection.md) | Mobile Application Framework — Flutter | Accepted |
| [0003](./0003-backend-architecture-style.md) | Backend Architecture Style — Modular Monolith, Microservices-Ready | Accepted |
| [0004](./0004-database-strategy.md) | Database Strategy — Polyglot Persistence | Accepted (relational); time-series engine resolved by 0013 |
| [0005](./0005-baas-platform-supabase.md) | BaaS Platform — Supabase | Accepted |
| [0006](./0006-iot-protocol-mqtt.md) | IoT Communication Protocol — MQTT | Accepted |
| [0007](./0007-api-style-rest.md) | API Style — REST | Accepted |
| [0008](./0008-offline-first-mobile-sync.md) | Offline-First Data Sync Strategy (Mobile) | Accepted (strategy) / Proposed (implementation) |
| [0009](./0009-authentication-and-rbac.md) | Authentication & RBAC Strategy | Accepted |
| [0010](./0010-diabetic-verification-mechanism.md) | Diabetic Verification Mechanism — Data Shape Only | Proposed (intentionally deferred — see RAH-DOC-005 §11) |
| [0011](./0011-material-design-3-as-design-system.md) | Material Design 3 (Material You) as the Official Design System | Accepted |

### Phase 1

| ID | Title | Status |
|---|---|---|
| [0012](./0012-backend-framework-selection.md) | Backend Implementation Language & Framework — TypeScript / NestJS | Accepted |
| [0013](./0013-time-series-storage-strategy.md) | Time-Series Telemetry Storage — Native PostgreSQL Partitioning | Accepted |
| [0014](./0014-payment-provider-abstraction.md) | Payment Provider Abstraction — Provider-Agnostic Adapter Pattern | Accepted |
| [0015](./0015-caching-strategy.md) | Server-Side Caching Strategy | Accepted |
| [0016](./0016-hosting-provider-selection.md) | Backend Hosting Provider | Proposed (indicative shortlist) |

### Phase 2

| ID | Title | Status |
|---|---|---|
| [0017](./0017-trilingual-support-fr-ar-en.md) | Trilingual Support — French, Arabic, English | Accepted |

### Phase 3

| ID | Title | Status |
|---|---|---|
| [0018](./0018-flutter-project-foundation.md) | Flutter Project Foundation — Structure, State Management, Routing, i18n Wiring | Accepted |
| [0019](./0019-map-rendering-and-geolocation-dependencies.md) | Map Rendering, Geolocation, and REST Client Dependencies (Feature 1) | Accepted |
| [0020](./0020-custom-marker-clustering.md) | Custom Marker Clustering (No Compatible Plugin) — US-01.1.2 | Accepted |
| [0021](./0021-map-search-and-filter-scope.md) | Map Search & Filter Scope — Client-Side, FR-MAP-05-Only Categories, No Speculative Filters — US-01.1.4/01.1.5 | Accepted |
| [0022](./0022-offline-cache-implementation-and-recenter-tracking.md) | Offline Cache Implementation (Drift, finalizing ADR-0008) and Continuous Position Tracking — US-01.1.6/01.1.7 | Accepted |
| [0023](./0023-explicit-mock-adapter-for-place-detail.md) | Explicit, Opt-In Mock Adapter for Place Detail (Cabin Status & Tariff) — US-01.2.2/01.2.3 | Accepted |
| [0024](./0024-bottom-navigation-shell-staging.md) | Bottom Navigation Shell Staging — Full 4-Tab Shell Now, Emergency as a Zero-Logic Placeholder — US-02.1.1 | Accepted |
| [0025](./0025-qibla-compass-sensor-package.md) | Qibla Compass Sensor Package — `flutter_compass` — US-02.1.2 | Accepted |
| [0026](./0026-unlock-timeout-and-stale-session-handling.md) | Unlock-Wait Timeout & Stale-Session Handling — Temporary Client-Side Policy Pending Backend/IoT SLA — US-04.4/US-04.6 | Accepted |
| [0027](./0027-qr-scanning-package.md) | QR-Scanning Package — `mobile_scanner` (+ `permission_handler`) — US-04.1 | Accepted |

## New ADRs
Copy [`template.md`](./template.md), number sequentially, and add a row above.

## Completion Status
✅ Complete for Phase 0, Phase 1, Phase 2, and Phase 3 through **EPIC-01 and EPIC-02 in full**, plus EPIC-04 in progress (0026 pre-implementation review decisions, 0027 QR-scanning package for US-04.1). Remaining open items: hosting provider final selection (0016), web component library for M3 parity on dashboards (Phase 2 execution), payment provider and diabetic-verification mechanism (both intentionally deferred pending external decisions — see Risk Register), brand typography/logo assets (blocker, see Phase 3 implementation log).

**26 ADRs total — 24 Accepted, 2 intentionally Proposed pending external business/vendor decisions.**
