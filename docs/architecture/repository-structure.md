# Repository Structure

| | |
|---|---|
| **Document ID** | RAH-DOC-022-REPO-STRUCTURE |
| **Phase** | Phase 1 — System Architecture |
| **Version** | 1.0 |
| **Related** | [System Architecture Document](./system-architecture.md) · [Module Dependency Diagram](./module-dependency-diagram.md) |

> This document specifies the structure. A matching **folder skeleton has been created in the repository** (directories + one `README.md` per folder explaining its purpose and boundaries) so Phase 4+ implementation has a ready home — **no source/config code has been added**, per the explicit Phase 1 instruction not to begin implementation.

## 1. Monorepo Rationale

A single repository hosts mobile, backend, web, both dashboards, shared design tokens, infrastructure-as-code, and documentation. This is chosen over polyrepo because: (a) the API contract ([API Architecture](../api/api-architecture.md)) is shared by four client surfaces and benefits from atomic cross-surface PRs when a contract changes; (b) the [Domain Model](./domain-model.md) and [ERD](../erd/erd.md) are single sources of truth best kept next to the code that implements them; (c) V1 team size ([ADR-0003](../adr/0003-backend-architecture-style.md)'s rationale) does not yet justify polyrepo's independent-release overhead.

## 2. Top-Level Structure

```
raahti/
├── docs/                         # Phase 0 + Phase 1 documentation (existing)
├── apps/
│   ├── mobile/                   # Flutter app — Phase 5
│   ├── backend/                  # NestJS modular monolith — Phase 4
│   ├── web/                      # Public website — Phase 6
│   ├── operator-dashboard/       # Operator Dashboard — Phase 7
│   └── sponsor-dashboard/        # Sponsor Dashboard — Phase 8
├── packages/
│   └── design-tokens/            # Shared Material 3 tokens (colors incl. RAH-DOC-002
│                                  # functional colors, typography, spacing) — Phase 2,
│                                  # consumed by web/operator-dashboard/sponsor-dashboard
├── infra/                        # Infrastructure-as-code, CI/CD pipeline defs — Phase 3/13
├── RAH-DOC-005-specification-plateforme-digitale.md
└── RAHATI-Master-Roadmap.md
```

**Note**: `apps/mobile` is Flutter-only and does **not** consume `packages/design-tokens` directly (Flutter's Material 3 theme is expressed in Dart, not shared CSS/JSON tokens) — it maintains its own theme definition kept in sync with `packages/design-tokens` by convention/design-review, not by build-time sharing. This asymmetry is intentional and documented here to prevent a future attempt to force a cross-language token-sharing mechanism that isn't needed.

## 3. Backend Structure (`apps/backend`)

```
apps/backend/
└── src/
    ├── modules/
    │   ├── identity/
    │   │   ├── domain/            # Entities, Value Objects, domain events, repository interfaces
    │   │   ├── application/       # Use-case services (application services), DTolayer-agnostic
    │   │   ├── infrastructure/    # Prisma repository impls, Supabase Auth client adapter
    │   │   └── interface/         # NestJS controllers, request/response DTOs, guards
    │   ├── station-network/       # (same 4 sub-folders)
    │   ├── third-party-places/    # (same 4 sub-folders)
    │   ├── slatoki/               # application/ + interface/ only — no domain/ or infrastructure/
    │   │                          # (owns no aggregate, see Module Dependency Diagram §2)
    │   ├── access-payment/        # (same 4 sub-folders) + infrastructure/payment-gateway/
    │   │                          #   (PaymentGateway port + adapters, ADR-0014)
    │   ├── emergency/             # application/ + interface/ only
    │   ├── notifications/         # (same 4 sub-folders) + infrastructure/channels/ (push, in-app)
    │   ├── sponsorship/           # (same 4 sub-folders)
    │   ├── operations/            # (same 4 sub-folders)
    │   └── analytics/             # application/ + infrastructure/ + interface/ (read-model, no domain/)
    ├── shared-kernel/             # Money, GeoPosition, LanguagePreference VOs; base repository
    │                              # interface; domain-event bus contract
    ├── platform/                  # Config, structured logging, health checks, correlation-id middleware
    └── main.ts                    # (not created yet — composition root, Phase 4)
```

### Per-Module Internal Structure
| Sub-folder | Contains | Depends on |
|---|---|---|
| `domain/` | Entities, Value Objects, Aggregates, domain events, `*RepositoryPort` interfaces | `shared-kernel/` only |
| `application/` | Use-case services, orchestration, transaction boundaries | `domain/` (own module), other modules' `application/` per the [dependency matrix](./module-dependency-diagram.md#3-allowed-dependency-matrix) |
| `infrastructure/` | Prisma repository implementations, MQTT client, external-system adapters | `domain/` (own module, implements its ports) |
| `interface/` | NestJS controllers, DTOs, guards, OpenAPI decorators | `application/` (own module) only |

A module with no `domain/` folder (`slatoki`, `emergency`) owns no persisted state by design — see [Module Dependency Diagram §5, rule 3](./module-dependency-diagram.md#5-rules-enforced-ci--review).

## 4. Frontend Apps Structure (indicative, detailed in Phase 2/5–8)

```
apps/mobile/            # Flutter — feature-first structure planned for Phase 5,
                         # mirroring backend bounded contexts (lib/features/<context>/)
apps/web/                # Phase 6
apps/operator-dashboard/ # Phase 7
apps/sponsor-dashboard/  # Phase 8
```

Detailed internal structure for these four apps is deferred to their respective implementation phases (5–8) — fixing it now would be premature given no frontend framework decision beyond Flutter (mobile) has been made for the three web surfaces (M3 web library selection is a Phase 2 item, [ADR-0011](../adr/0011-material-design-3-as-design-system.md)).

## 5. What Was Scaffolded vs. Documented Only

| Scaffolded now (folders + README only, no code) | Documented only, scaffolded later |
|---|---|
| `apps/backend/src/modules/*/{domain,application,infrastructure,interface}` | `apps/mobile/*` internals (Phase 5) |
| `apps/backend/src/shared-kernel/`, `apps/backend/src/platform/` | `apps/web`, `apps/operator-dashboard`, `apps/sponsor-dashboard` internals (Phases 6–8) |
| `packages/design-tokens/` | `infra/` internals (Phase 3/13) |

## 6. Completion Status

| Item | Status |
|---|---|
| Full repository tree specified | ✅ Complete |
| Backend module internal structure specified per Clean Architecture layer | ✅ Complete |
| Folder skeleton (no code) created in repository | ✅ Complete |
| Frontend app internals | ⚠️ Deferred to Phases 2/5–8 by design |

**Phase 1 deliverable 3 of 10 — Repository Structure: COMPLETE.**
