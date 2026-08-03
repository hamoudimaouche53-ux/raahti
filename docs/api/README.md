# API Contracts

**Status**: Populated in **Phase 1 — System Architecture**.

- [`api-architecture.md`](./api-architecture.md) — versioning, auth, error schema, pagination, bilingual content, idempotency, rate limiting, and real-time channel conventions.
- [`openapi.yaml`](./openapi.yaml) — the authoritative, reviewed OpenAPI 3.0 contract for the V1 surface (Identity, Places, Slatoki, Emergency, Access & Payment, Operations, Sponsorship, Notifications). Every operation cites the SRS `FR-*` requirement it implements.

Implementation (Phase 4) must match this contract; CI enforces it via a generated-vs-authored contract diff (see [Deployment Architecture §3](../deployment/deployment-architecture.md#3-cicd-pipeline-stages-to-be-implemented-phase-3)).
