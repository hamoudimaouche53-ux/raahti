# System Architecture Document

| | |
|---|---|
| **Document ID** | RAH-DOC-020-SYSTEM-ARCHITECTURE |
| **Phase** | Phase 1 — System Architecture |
| **Version** | 1.0 |
| **Status** | Draft for Review |
| **Date** | 2026-07-31 |
| **Baseline** | [RAH-DOC-005](../../RAH-DOC-005-specification-plateforme-digitale.md) (immutable) · [Phase 0 documentation set](../README.md) (immutable) |
| **Related** | [Architecture Overview (Phase 0)](./architecture-overview.md) · [Domain Model](./domain-model.md) · [Module Dependency Diagram](./module-dependency-diagram.md) · [Repository Structure](./repository-structure.md) · [API Architecture](../api/api-architecture.md) · [Security Architecture](./security-architecture.md) · [ADR index](../adr/README.md) |

> **Baseline discipline**: this document extends, and never alters, the [Phase 0 Architecture Overview](./architecture-overview.md). Every Phase 1 decision either (a) resolves a Phase 0 open question via a new ADR, or (b) adds implementation-level detail underneath an already-accepted Phase 0 decision. Where a decision depends on an external vendor choice not yet approved (payment provider, diabetic-verification process), this document specifies the extension point and stops — it does not assume a vendor.

## 1. Purpose and Scope

This is the master Phase 1 architecture document: it fixes the production-ready system design at the level needed to start implementation-ready module and API design (Phase 1 deliverables 2–9), without writing implementation code. It supersedes no Phase 0 content; §4 below shows exactly what Phase 1 added on top of the Phase 0 [Architecture Overview §4](./architecture-overview.md#4-technology-stack) technology table.

## 2. Architectural Principles (recap, unchanged from Phase 0)

Clean Architecture · Domain-Driven Design · SOLID · API-First · Offline-First — see [Architecture Overview §1](./architecture-overview.md#1-architectural-principles) for the full statement. Phase 1 makes each principle concrete:

| Principle | Phase 0 statement | Phase 1 concretization |
|---|---|---|
| Clean Architecture | 5-layer dependency rule | NestJS module-per-context + DI-token repository ports (§3, [ADR-0012](../adr/0012-backend-framework-selection.md)) |
| DDD | 10 bounded contexts | 1:1 NestJS module mapping ([Module Dependency Diagram](./module-dependency-diagram.md)) |
| SOLID | Applied at class level | Enforced via DI container, interface segregation per port (`PaymentGateway`, `NotificationSender`, etc.) |
| API-First | All clients share one API | `docs/api/openapi.yaml` authored and reviewed before controller implementation ([API Architecture](../api/api-architecture.md)) |
| Offline-First | Mobile designed around local cache | [Offline & Sync Architecture](./offline-sync-architecture.md) |

## 3. Layered Architecture — Implementation Mapping

```
┌───────────────────────────────────────────────────────────────────┐
│ Presentation      Flutter (Material 3) · Web (M3-aligned) ·        │
│                    Operator/Sponsor Dashboards                     │
├───────────────────────────────────────────────────────────────────┤
│ API / Interface   NestJS Controllers, DTOs (class-validator),      │
│                    Guards (authn/authz), Interceptors (logging,     │
│                    error mapping) — see docs/api/                  │
├───────────────────────────────────────────────────────────────────┤
│ Application       NestJS Providers — Use-case services,            │
│                    orchestration, transaction boundaries, no       │
│                    framework I/O beyond DI                         │
├───────────────────────────────────────────────────────────────────┤
│ Domain            Plain TypeScript classes — Entities, Value       │
│                    Objects, Aggregates, Domain Events, Domain      │
│                    Services. Zero imports from NestJS, Prisma,     │
│                    or any I/O library.                             │
├───────────────────────────────────────────────────────────────────┤
│ Infrastructure    Prisma repositories (Postgres/PostGIS), MQTT     │
│                    client, PaymentGateway adapters, Supabase       │
│                    Auth/Storage/Realtime clients, Notification     │
│                    channel senders                                 │
└───────────────────────────────────────────────────────────────────┘
```

**Dependency rule enforcement**: Domain has no outward imports (verified by a lint rule — ESLint `import/no-restricted-paths` — configured per module, see [Repository Structure](./repository-structure.md)). Application depends only on Domain and on repository/port *interfaces* declared in Domain. Infrastructure implements those interfaces and is wired via NestJS `Module.providers` at the composition root. Presentation (API/Interface layer) depends only on Application.

## 4. Technology Stack — Phase 1 Resolutions

Extends [Architecture Overview §4](./architecture-overview.md#4-technology-stack); rows marked *(Phase 1)* are new since Phase 0.

| Concern | Phase 0 status | Phase 1 resolution | ADR |
|---|---|---|---|
| Backend language/framework | Open (OQ5) | **TypeScript / NestJS** | [ADR-0012](../adr/0012-backend-framework-selection.md) *(Phase 1)* |
| ORM / query layer | Not specified | **Prisma** + raw SQL for PostGIS spatial queries | [ADR-0012](../adr/0012-backend-framework-selection.md) *(Phase 1)* |
| Time-series storage | Open (OQ6) | **Native Postgres range partitioning** on Supabase | [ADR-0013](../adr/0013-time-series-storage-strategy.md) *(Phase 1)* |
| Payment integration | Provider TBD | **Provider-agnostic `PaymentGateway` port** + mock adapter for development | [ADR-0014](../adr/0014-payment-provider-abstraction.md) *(Phase 1)* |
| Server-side caching | Not specified | HTTP caching + indexes + in-process memoization; no dedicated cache store at V1 | [ADR-0015](../adr/0015-caching-strategy.md) *(Phase 1)* |
| Hosting provider | Not specified | Indicative shortlist (AWS / OVHcloud / container PaaS); final choice pending | [ADR-0016](../adr/0016-hosting-provider-selection.md) *(Phase 1, Proposed)* |
| Mobile framework | Flutter | Unchanged | [ADR-0002](../adr/0002-mobile-framework-selection.md) |
| Design system | Material Design 3 | Unchanged, extended with web-dashboard M3 parity note (§9) | [ADR-0011](../adr/0011-material-design-3-as-design-system.md) |
| BaaS | Supabase | Unchanged | [ADR-0005](../adr/0005-baas-platform-supabase.md) |
| API style | REST | Unchanged, now contract-authored (§6) | [ADR-0007](../adr/0007-api-style-rest.md) |
| IoT transport | MQTT | Unchanged | [ADR-0006](../adr/0006-iot-protocol-mqtt.md) |

## 5. Module Structure

Ten bounded contexts from the [Domain Model](./domain-model.md) become ten NestJS feature modules, plus two cross-cutting modules (`SharedKernelModule`, `PlatformModule` for logging/config/health). Full allowed-dependency matrix, layering rules, and a `graph LR` diagram are in the dedicated [Module Dependency Diagram](./module-dependency-diagram.md) document (Deliverable 2).

## 6. API Architecture (summary)

All public contracts are authored in `docs/api/openapi.yaml` **before** controller implementation, per API-First. Full versioning policy, auth conventions, error schema, and pagination rules are in [API Architecture](../api/api-architecture.md) (Deliverable 4).

## 7. Data Architecture

The [ERD](../erd/erd.md) (Phase 0) is unchanged in entity/attribute terms. Phase 1 adds:
- **PostGIS** confirmed as the spatial extension backing `station.position` and `third_party_place.position` (`geography(Point,4326)` columns use `ST_DWithin`/`ST_Distance` for nearby queries, replacing the Phase 0 ERD's generic "GIST index" note with a concrete PostGIS implementation).
- **Prisma schema** as the canonical, generated-from, single definition of the relational schema — kept in 1:1 correspondence with the ERD; any drift is a Phase 1+ code-review blocker.
- Data flow between contexts, stores, and external systems: see [Data Flow Diagrams](./data-flow-diagrams.md) (Deliverable 5).

## 8. Cross-Cutting Architecture

Authentication/authorization, encryption, and threat posture are detailed in [Security Architecture](./security-architecture.md) (Deliverable 7). Caching, notification dispatch, and error-handling conventions are in [Cross-Cutting Architecture](./cross-cutting-architecture.md). Offline/sync is in [Offline & Sync Architecture](./offline-sync-architecture.md) (Deliverable 8).

## 9. Design System Continuity

Material Design 3 ([ADR-0011](../adr/0011-material-design-3-as-design-system.md)) remains the official design system for every surface. Phase 1 adds one implementation note: the Operator and Sponsor Dashboards (web) will use an M3-compliant web component approach — final library selection is a Phase 2 item (already flagged in ADR-0011's consequences), but the **architectural contract** is fixed now: dashboard frontends consume the same REST API and DTOs as the mobile app, so no dashboard-specific backend logic is needed to support M3 theming (theming is entirely a Presentation-layer concern, per the layering in §3).

## 10. Non-Functional Targets (unchanged, restated for traceability)

NFR-PERF-01 (≤1.5s), NFR-AVAIL-01 (≥99.5%), NFR-SEC-01…04, NFR-A11Y-01…05 — see [SRS §8](../srs/SRS.md#8-non-functional-requirements). Phase 1's [Deployment Architecture](../deployment/deployment-architecture.md) specifies how scalability, observability, and backups are engineered to meet these targets.

## 11. Assumptions
- NestJS/TypeScript/Prisma are assumed compatible with the team's hiring plan; no staffing constraint was communicated that would rule this out.
- PostGIS is assumed enabled on the Supabase project (it is on Supabase's supported-extensions list); this is a Phase 3 provisioning checklist item, not an architectural risk.

## 12. Open Questions
- Final hosting provider ([ADR-0016](../adr/0016-hosting-provider-selection.md)) — pending business decision.
- Payment provider, diabetic-verification process — intentionally out of this architecture's scope; extension points defined ([ADR-0014](../adr/0014-payment-provider-abstraction.md), [ADR-0010](../adr/0010-diabetic-verification-mechanism.md)).
- M3 web component library for dashboards — Phase 2 item.

## 13. Completion Status

| Item | Status |
|---|---|
| Layered architecture mapped to concrete implementation technology | ✅ Complete |
| Technology stack fully resolved except explicitly-deferred vendor items | ✅ Complete |
| Cross-references to all other Phase 1 deliverables | ✅ Complete |

**Phase 1 deliverable 1 of 10 — System Architecture Document: COMPLETE.**
