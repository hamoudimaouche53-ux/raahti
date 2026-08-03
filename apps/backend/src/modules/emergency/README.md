# emergency module

Bounded context: **Emergency Mode — one-tap emergency targeting and discount-eligibility orchestration.**

Owns no aggregate (see `docs/architecture/domain-model.md` §7) — reads Identity & Access (verification status) and Station Network (nearest accessible facility) rather than duplicating their state. Has only:
- `application/` — `EmergencyFacilityFinder` and `EmergencyDiscountPolicy` domain services.
- `interface/` — NestJS controllers, DTOs, guards.

No `domain/` or `infrastructure/` folder by design — this module persists nothing of its own.
