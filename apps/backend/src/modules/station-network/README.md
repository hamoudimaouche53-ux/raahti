# station-network module

Bounded context: **Station Network — RAHETI stations, cabins, Slatoki tent equipment state, real-time availability.**

Layering (Clean Architecture — see `docs/architecture/system-architecture.md` §3):
- `domain/` — Entities, Value Objects, Aggregates, domain events, repository port interfaces. No framework imports.
- `application/` — Use-case services, orchestration, transaction boundaries.
- `infrastructure/` — Prisma repository implementations and external-system adapters.
- `interface/` — NestJS controllers, DTOs, guards.

No implementation code yet — Phase 1 (System Architecture) scaffold only. See `docs/architecture/module-dependency-diagram.md` for allowed dependencies.
