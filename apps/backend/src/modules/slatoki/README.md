# slatoki module

Bounded context: **Slatoki — Qibla direction domain service and prayer/ablution filtering/verification-level logic.**

Owns no aggregate (see `docs/architecture/domain-model.md` §4) — reads Station Network (Slatoki tent state) and Third-Party Places (tagged mosques) rather than duplicating their state. Has only:
- `application/` — `QiblaDirectionCalculator` domain service, filtering/verification-level use cases.
- `interface/` — NestJS controllers, DTOs, guards.

No `domain/` or `infrastructure/` folder by design — this module persists nothing of its own.
