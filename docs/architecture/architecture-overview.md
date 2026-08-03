# Architecture Overview

| | |
|---|---|
| **Document ID** | RAH-DOC-010-ARCH-OVERVIEW |
| **Phase** | Phase 0 — Analysis (refined in Phase 1 — System Architecture) |
| **Version** | 1.0 |
| **Status** | Draft for Review |
| **Date** | 2026-07-31 |
| **Source of Truth** | [RAH-DOC-005 §7](../../RAH-DOC-005-specification-plateforme-digitale.md#7-architecture-technique-indicative) (indicative architecture) |
| **Related** | [SRS](../srs/SRS.md) · [C4 Diagrams](./c4-context.md) · [Domain Model](./domain-model.md) · [ERD](../erd/erd.md) · [ADRs](../adr/README.md) |

> RAH-DOC-005 §7 explicitly frames its architecture recommendations as **indicative, to be confirmed with the engineering team**. This document is that confirmation pass for Phase 0/1: it operationalizes §7 into a concrete architecture without contradicting any stated requirement. Every deviation from a literal reading of §7 (e.g., resolving "REST or GraphQL" to REST) is recorded as an [ADR](../adr/README.md) with rationale, not decided silently.

## 1. Architectural Principles

Per the Master Roadmap (Phase 1) and RAH-DOC-005 §7, the system is built on:

- **Clean Architecture** — dependency rule flows inward: UI/Infrastructure → Application → Domain, with the Domain layer having zero framework dependencies.
- **Domain-Driven Design (DDD)** — the system is decomposed into bounded contexts (see [Domain Model](./domain-model.md)) aligned to RAH-DOC-005's five digital-layer components plus the domain concerns each implies (Identity, Stations, Slatoki, Payments, Notifications, Sponsorship, IoT/Telemetry, Analytics).
- **SOLID** — applied at the module/class level within each bounded context's application and domain layers.
- **API-First** — all client surfaces (mobile, dashboards, website) consume the same versioned, contract-defined backend API; no client talks to the database directly.
- **Offline-First** — the mobile app is designed around local cache and eventual consistency by default (RAH-DOC-005 §2.1, §9), not as a fallback bolted on later.

## 2. System Layers (Clean Architecture)

```
┌─────────────────────────────────────────────────────────────┐
│ Presentation           Mobile (Flutter/M3) · Web · Dashboards │
├─────────────────────────────────────────────────────────────┤
│ API / Interface        REST endpoints, DTOs, auth middleware  │
├─────────────────────────────────────────────────────────────┤
│ Application            Use cases / application services,      │
│                        orchestration, transaction boundaries  │
├─────────────────────────────────────────────────────────────┤
│ Domain                 Entities, Value Objects, Aggregates,   │
│                        Domain Events, Domain Services          │
│                        (framework-agnostic, no I/O)            │
├─────────────────────────────────────────────────────────────┤
│ Infrastructure         Postgres/Supabase, MQTT broker,        │
│                        payment SDKs, notification providers    │
└─────────────────────────────────────────────────────────────┘
```

The Domain layer is the only layer with no outward dependency; Application depends on Domain; Infrastructure and Presentation depend inward on Application/Domain via interfaces (ports), not the reverse — see [ADR-0003](../adr/0003-backend-architecture-style.md).

## 3. Bounded Contexts (summary)

Full detail in [Domain Model](./domain-model.md). Contexts map directly to RAH-DOC-005 functional areas so that every requirement in the SRS has an unambiguous owning context:

| Bounded Context | Owns | RAH-DOC-005 source |
|---|---|---|
| Identity & Access | Users, roles, verified-diabetic status, auth | §2.6, §4, §5 |
| Station Network | Stations, Cabins, availability, telemetry ingestion | §2.1, §2.2, §6, §8 |
| Third-Party Places | Community/declarative places (mosques, businesses) | §2.1, §2.2 |
| Slatoki | Prayer/ablution spaces, Qibla, tent equipment state | §2.3 |
| Access & Payment | QR sessions, unlock orchestration, transactions | §2.5, §7 |
| Emergency Mode | Emergency profile targeting, discount eligibility | §2.4 |
| Notifications | Availability alerts, operator alerts, payment confirmations | §6 |
| Sponsorship | Sponsors, campaigns, aggregated reporting | §5 |
| Operations | Maintenance scheduling, alert triage | §4 |
| Analytics & BI | Frequentation history, exportable reports | §4, §5, Roadmap Phase 11 |

## 4. Technology Stack

| Concern | Choice | Status | Rationale / Source |
|---|---|---|---|
| Mobile app | Flutter | Decided | Master Roadmap Phase 5; resolves RAH-DOC-005 §7's indicative "React Native or Flutter" — [ADR-0002](../adr/0002-mobile-framework-selection.md) |
| Mobile design system | Material Design 3 (Material You) | Decided | Explicit product instruction; [ADR-0011](../adr/0011-material-design-3-as-design-system.md) |
| Backend API style | REST | Decided | Resolves RAH-DOC-005 §7's indicative "REST or GraphQL" — [ADR-0007](../adr/0007-api-style-rest.md) |
| Backend architecture style | Modular monolith, DDD bounded-context modules, microservices-ready | Decided | Operationalizes §7's indicative "microservices" recommendation for a V1-appropriate risk profile — [ADR-0003](../adr/0003-backend-architecture-style.md) |
| BaaS / Cloud platform | Supabase (Postgres, Auth, Storage, Realtime) | Decided | Master Roadmap Phase 3 |
| Transactional database | PostgreSQL (via Supabase) | Decided | §7 ("base relationnelle"); Master Roadmap Phase 3 |
| Time-series store (IoT) | To be selected in Phase 1 (candidates: TimescaleDB extension on Postgres, or dedicated TSDB) | Open | §7 ("base orientée séries temporelles") — [ADR-0004](../adr/0004-database-strategy.md) |
| IoT transport | MQTT | Decided | §7, §9; Master Roadmap Phase 9 — [ADR-0006](../adr/0006-iot-protocol-mqtt.md) |
| Auth | Supabase Auth, custom RBAC layer | Decided | Master Roadmap Phase 1 (RBAC), Phase 3 (Supabase Auth) — [ADR-0009](../adr/0009-authentication-and-rbac.md) |
| Payments | Local mobile/card provider(s), PCI-DSS-aligned | Open | §7, §11 — provider selection explicitly deferred; see PRD OQ2 |
| Web platform | Bilingual FR/AR site, SEO-optimized, M3-aligned visual language | Decided | §3 |
| CI/CD, monitoring, backups | Per Master Roadmap Phase 3 | Deferred to Phase 3 | Out of Phase 0 detail scope |
| Deployment/hosting | Regional Cloud presence near the Algerian market | Decided (provider TBD) | §7 |

## 5. Cross-Cutting Concerns

- **Offline-First (mobile)**: local cache of map/place data with a visible freshness indicator (SRS FR-MAP-07); write operations (payment, unlock) require connectivity by nature and are not queued offline.
- **Internationalization**: FR/AR with native RTL across every surface, not only the mobile app (SRS NFR-I18N-01).
- **Accessibility**: WCAG 2.2 AA baseline, delivered through Material Design 3 components (SRS NFR-A11Y-02…05).
- **Security**: encryption in transit/at rest, strong dashboard authentication, PCI-DSS-aligned payment handling, RBAC across Operator/Sponsor/Admin roles (SRS §8.3).
- **Observability**: monitoring and backups scoped to Master Roadmap Phase 3; not detailed further in Phase 0.
- **Auditability**: full transaction/access logging at the Cloud platform (SRS FR-CLD-04), feeding both operator support and future BI (Master Roadmap Phase 11).

## 6. Real-Time Data Flow (summary)

Station → MQTT → Cloud ingestion service → Station Network context (state update) → Realtime channel (Supabase Realtime) → Mobile app / Operator Dashboard subscribers. See [C4 Container Diagram](./c4-container.md) for the full component-to-component view and [ERD](../erd/erd.md) for the underlying data model.

## 7. Deployment Topology (indicative)

Detailed CI/CD, environment, and infrastructure-as-code specification is a Phase 3/13 deliverable (`docs/deployment/`, currently a scoped placeholder — see [docs/deployment/README.md](../deployment/README.md)). At Phase 0, the only fixed constraint is: single Cloud backend, regionally hosted near Algeria, serving all client surfaces through the same API surface (§7).

## 8. Assumptions
- Supabase is treated as a confirmed choice because it appears explicitly in the Master Roadmap (Phase 3), even though RAH-DOC-005 §7 only specifies generic "Cloud hosting" requirements — this is additive, not contradictory.
- No specific backend programming language/framework is fixed at Phase 0; RAH-DOC-005 does not name one, and the Master Roadmap does not either. This is deferred to Phase 1 System Architecture as an explicit open item (see §9).

## 9. Open Questions
- OQ5: Backend implementation language/framework is not specified anywhere in the source documents — to be decided in Phase 1 with the engineering team, consistent with §7's "à valider avec l'équipe d'ingénierie retenue."
- OQ6: Time-series store selection for IoT telemetry (TimescaleDB vs. dedicated TSDB) — to be resolved in Phase 1/Phase 3.
- See also PRD OQ1–OQ4.

## 10. Completion Status

| Item | Status |
|---|---|
| Architectural principles documented | ✅ Complete |
| Layering model documented | ✅ Complete |
| Bounded context summary (full detail in Domain Model) | ✅ Complete |
| Technology stack decisions recorded with ADR links | ✅ Complete (2 items open, tracked) |
| Cross-cutting concerns documented | ✅ Complete |

**Phase 0 document 3 of 10 — Architecture Overview: COMPLETE.**
