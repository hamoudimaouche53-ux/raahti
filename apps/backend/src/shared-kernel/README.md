# shared-kernel

Cross-cutting Domain-layer building blocks shared by every module (see `docs/architecture/module-dependency-diagram.md` §2):
- Common Value Objects: `Money`, `GeoPosition`, `LanguagePreference`.
- Base repository interface conventions.
- Domain-event bus contract (publish/subscribe interface used by all modules' `application/` layers).

Every module may depend on shared-kernel; shared-kernel depends on nothing else. No implementation code yet (Phase 1 scaffold only).
