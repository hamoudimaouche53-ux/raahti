# ADR-0012: Backend Implementation Language & Framework — TypeScript / NestJS

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Engineering team |
| **Phase** | Phase 1 — System Architecture |
| **Resolves** | [Architecture Overview OQ5](../architecture/architecture-overview.md#9-open-questions), Risk Register R-03 |

## Context
RAH-DOC-005 §7 names no backend language or framework. Phase 0 fixed the surrounding constraints that any candidate must satisfy: modular monolith with DDD bounded-context modules ([ADR-0003](./0003-backend-architecture-style.md)), Clean Architecture layering, REST/API-First ([ADR-0007](./0007-api-style-rest.md)), Supabase/PostgreSQL+PostGIS as the data platform ([ADR-0005](./0005-baas-platform-supabase.md)), and MQTT-based IoT ingestion ([ADR-0006](./0006-iot-protocol-mqtt.md)).

## Decision
Use **TypeScript** on **Node.js**, with **NestJS** as the application framework, for the API Backend container.

- NestJS's module system maps directly onto the bounded contexts in the [Domain Model](../architecture/domain-model.md) (one `NestModule` per context), each exposing only its public application-service interface to other modules — enforcing the module boundaries required by [ADR-0003](./0003-backend-architecture-style.md) at the framework level (import/export declarations), not just by convention.
- NestJS's dependency-injection container is used to wire Clean Architecture's dependency-inversion: Domain-layer repository *interfaces* are declared as DI tokens; Infrastructure-layer Postgres/MQTT adapters are the only classes that implement and register against those tokens.
- **Prisma** is the ORM/query layer against Supabase PostgreSQL, chosen for its type-safe schema-to-code generation (matching the [ERD](../erd/erd.md) 1:1) and first-class migration tooling; raw SQL/`$queryRaw` is used specifically for PostGIS spatial queries (`ST_DWithin`, etc.) that Prisma's query builder does not express natively.
- **class-validator**/**class-transformer** enforce DTO validation at the API/Interface layer, keeping invalid input out of the Application layer entirely.
- OpenAPI documentation ([API Architecture](../api/api-architecture.md)) is generated from NestJS decorators via `@nestjs/swagger`, keeping the contract and the implementation from silently drifting apart — while the contract-first OpenAPI file authored in Phase 1 (`docs/api/openapi.yaml`) remains the reviewed source of truth that generated output must match.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| NestJS / TypeScript (chosen) | DI + module system fits DDD/Clean Architecture directly; single language across API and (optionally) shared validation code; strong Supabase JS client and Prisma support; large hiring pool | Node's single-threaded event loop requires care for CPU-bound work (not expected to be significant for this domain) |
| Python / FastAPI | Fast to prototype; good async support; strong typing via Pydantic | Weaker first-party DI/module-boundary enforcement; DDD structure must be hand-rolled and policed by convention only |
| Dart / Serverpod | Single language across mobile ([ADR-0002](./0002-mobile-framework-selection.md)) and backend | Serverpod's ecosystem, DDD tooling, and hiring pool are far less mature than NestJS's for an enterprise backend |
| Java / Spring Boot | Extremely mature DDD/Clean Architecture tooling, enterprise track record | Heavier operational footprint (JVM) and slower iteration speed than justified for current team size/scale |

## Consequences
### Positive
- Module boundaries from [ADR-0003](./0003-backend-architecture-style.md) become structurally enforced, not just documented, directly reducing Risk R-10 (boundary erosion).
- Type-safe, end-to-end (DB schema → domain → API DTO → generated OpenAPI) reduces a whole class of contract-drift bugs.

### Negative / Trade-offs
- Introduces a second language (TypeScript) alongside Dart (mobile) — accepted as the better trade-off versus weaker DDD tooling in Dart-native backend options.
- Raw SQL is required for PostGIS-specific queries, meaning the Infrastructure layer cannot be 100% ORM-abstracted for the Station Network and Third-Party Places contexts.

## Related
- [ADR-0003](./0003-backend-architecture-style.md), [ADR-0005](./0005-baas-platform-supabase.md), [System Architecture Document](../architecture/system-architecture.md), [Repository Structure](../architecture/repository-structure.md)
