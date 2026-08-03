# RAHATI Documentation

Single source of truth for functional scope: [`RAH-DOC-005 — Spécification de Plateforme Digitale`](../RAH-DOC-005-specification-plateforme-digitale.md). Phase sequencing: [`RAHATI Master Roadmap`](../RAHATI-Master-Roadmap.md).

## Phase 0 — Analysis (Complete)

See the [Phase 0 Completion Report](./phase-0-completion-report.md) for full status, decisions, open items, and the Phase 1 recommendation.

| Document | Path |
|---|---|
| Product Requirements Document | [`prd/PRD.md`](./prd/PRD.md) |
| Software Requirements Specification | [`srs/SRS.md`](./srs/SRS.md) |
| Architecture Overview | [`architecture/architecture-overview.md`](./architecture/architecture-overview.md) |
| C4 — System Context | [`architecture/c4-context.md`](./architecture/c4-context.md) |
| C4 — Container | [`architecture/c4-container.md`](./architecture/c4-container.md) |
| C4 — Component | [`architecture/c4-component.md`](./architecture/c4-component.md) |
| Domain Model (DDD) | [`architecture/domain-model.md`](./architecture/domain-model.md) |
| Entity-Relationship Diagram | [`erd/erd.md`](./erd/erd.md) |
| Architecture Decision Records | [`adr/README.md`](./adr/README.md) |
| Product Backlog | [`backlog/product-backlog.md`](./backlog/product-backlog.md) |
| Risk Register | [`decisions/risk-register.md`](./decisions/risk-register.md) |
| Phase 0 Completion Report | [`phase-0-completion-report.md`](./phase-0-completion-report.md) |

## Phase 1 — System Architecture (Complete)

See the [Phase 1 Completion Report](./phase-1-completion-report.md) for full status, decisions, open items, and Phase 2 readiness.

| Document | Path |
|---|---|
| System Architecture Document | [`architecture/system-architecture.md`](./architecture/system-architecture.md) |
| Module Dependency Diagram | [`architecture/module-dependency-diagram.md`](./architecture/module-dependency-diagram.md) |
| Repository Structure | [`architecture/repository-structure.md`](./architecture/repository-structure.md) |
| API Architecture | [`api/api-architecture.md`](./api/api-architecture.md) |
| OpenAPI Contract | [`api/openapi.yaml`](./api/openapi.yaml) |
| Data Flow Diagrams | [`architecture/data-flow-diagrams.md`](./architecture/data-flow-diagrams.md) |
| Sequence Diagrams | [`architecture/sequence-diagrams.md`](./architecture/sequence-diagrams.md) |
| Security Architecture | [`architecture/security-architecture.md`](./architecture/security-architecture.md) |
| Offline & Sync Architecture | [`architecture/offline-sync-architecture.md`](./architecture/offline-sync-architecture.md) |
| Cross-Cutting Architecture (caching, notifications, errors) | [`architecture/cross-cutting-architecture.md`](./architecture/cross-cutting-architecture.md) |
| Deployment Architecture | [`deployment/deployment-architecture.md`](./deployment/deployment-architecture.md) |
| Phase 2 Implementation Plan | [`phase-2-implementation-plan.md`](./phase-2-implementation-plan.md) |
| Phase 1 Completion Report | [`phase-1-completion-report.md`](./phase-1-completion-report.md) |

New in Phase 1: ADRs 0012–0016 (see [ADR index](./adr/README.md)); a repository folder skeleton under `apps/`, `packages/`, `infra/` (folders + README stubs only, no code — see [Repository Structure §5](./architecture/repository-structure.md#5-what-was-scaffolded-vs-documented-only)).

## Phase 2 — UI/UX Design System and Product Design (Complete)

See the [Phase 2 Completion Report](./phase-2-completion-report.md) for full status, decisions, open items, and Phase 3 readiness.

| Document | Path |
|---|---|
| Design System Specification | [`design/design-system-specification.md`](./design/design-system-specification.md) |
| Foundations (color, type, icon, elevation, motion, spacing, shape, states) | [`design/foundations.md`](./design/foundations.md) |
| Component Library Specification | [`design/component-library.md`](./design/component-library.md) |
| Design Tokens (JSON) | [`packages/design-tokens/`](../packages/design-tokens/README.md) |
| Responsive Layout Guidelines | [`design/responsive-layout-guidelines.md`](./design/responsive-layout-guidelines.md) |
| Complete User Flows | [`design/user-flows.md`](./design/user-flows.md) |
| Screen Inventory (45 screens → Epic → User Story) | [`design/screen-inventory.md`](./design/screen-inventory.md) |
| Wireframes (all 45 screens) | [`design/wireframes/`](./design/wireframes/README.md) |
| Interactive Prototype (15 flagship screens, published link) | [`design/interactive-prototype.md`](./design/interactive-prototype.md) |
| Assumptions & Open Questions *(kept separate from approved requirements, per instruction)* | [`design/assumptions-and-open-questions.md`](./design/assumptions-and-open-questions.md) |
| Phase 2 Completion Report | [`phase-2-completion-report.md`](./phase-2-completion-report.md) |

New in Phase 2: [ADR-0017](./adr/0017-trilingual-support-fr-ar-en.md) (trilingual FR/AR/EN support — the one baseline extension this phase introduced, with small marked addenda to the [SRS](./srs/SRS.md#phase-2-addendum) and [ERD](./erd/erd.md#36-user-account-src-ext)); `packages/design-tokens/` populated with 7 JSON files.

## Phase 3 — Flutter Implementation (In Progress)

See the [Phase 3 Implementation Log](./phase-3-implementation-log.md) — a living document, one entry per completed feature, each with files changed, architecture decisions, and `flutter analyze`/`flutter test` results. Feature 0 (Project Foundation: theme, localization, routing, DI, SCR-001 Splash) is complete; see [`apps/mobile/`](../apps/mobile/README.md) for the running code and [ADR-0018](./adr/0018-flutter-project-foundation.md) for the foundation's architecture decisions.

## Scaffolded for Later Phases

| Folder | Populated in | Status |
|---|---|---|
| `apps/web`, `apps/operator-dashboard`, `apps/sponsor-dashboard` internals | Phases 6–8 | Folder + README only |
| `infra/` execution (IaC, CI/CD) | Phase 3 — Cloud / Phase 13 — Production | Folder + README only |

## Reading Order

For a new team member: PRD → SRS → Architecture Overview → C4 diagrams → Domain Model → ERD → ADRs → Backlog → Risk Register → System Architecture Document → Module Dependency Diagram → API Architecture → Sequence Diagrams → Security Architecture → Offline & Sync Architecture → Deployment Architecture → Design System Specification → Foundations → Component Library → Screen Inventory → Wireframes → Interactive Prototype → Phase 3 Implementation Log.

## Conventions

- Every requirement cites its RAH-DOC-005 source section (`§n`); additions beyond RAH-DOC-005 are marked `[NEW]` or recorded as an ADR — see [ADR-0001](./adr/0001-rah-doc-005-as-single-source-of-truth.md).
- Requirement IDs: `FR-<MODULE>-nn` (functional), `NFR-<CATEGORY>-nn` (non-functional) — defined in the [SRS](./srs/SRS.md).
- Backlog IDs: `EPIC-nn` → `FEAT-nn.n` → `US-nn.n.n`. Screen IDs: `SCR-nnn` — defined in the [Screen Inventory](./design/screen-inventory.md).
- ADRs are numbered sequentially (`000n`) in [MADR](https://adr.github.io/madr/) format; see [`adr/template.md`](./adr/template.md) for new entries.
- Phase 0, Phase 1, and Phase 2 documentation are treated as an **immutable baseline** as of Phase 2 completion — later phases extend them via new ADRs/documents rather than editing prior decisions in place. Phase-specific assumptions (values not fixed by any prior requirement) are kept in dedicated documents (e.g. [`design/assumptions-and-open-questions.md`](./design/assumptions-and-open-questions.md)) separate from approved requirements.
