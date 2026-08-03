# ADR-0001: RAH-DOC-005 as the Functional Single Source of Truth

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Product team |
| **RAH-DOC-005 reference** | Whole document |

## Context
Phase 0 must produce a large, interlocking documentation set (PRD, SRS, architecture, ERD, domain model, backlog). Without an explicit anchor, downstream documents risk drifting from — or silently reinterpreting — the original product specification (RAH-DOC-005) as they get more technical.

## Decision
RAH-DOC-005 is the **single source of truth for functional scope**. Every requirement, entity, and user flow in every Phase 0 document must trace back to a specific RAH-DOC-005 section, marked inline (e.g. `[§2.3]`). Where a Phase 0 document needs to go beyond RAH-DOC-005 (fill a gap, resolve an "either/or" left indicative in §7, or incorporate a constraint communicated after RAH-DOC-005 such as Material Design 3), it must mark the addition explicitly (`[NEW]`, "Assumption", or an ADR) rather than blend it silently into the source requirements.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| Treat Master Roadmap as SSOT | Reflects newest phase-sequencing intent | Roadmap is a phase list, not a functional spec — would leave feature detail undefined |
| No explicit SSOT, synthesize freely | Faster initial drafting | High risk of silent requirement drift across 10 documents |

## Consequences
### Positive
- Every downstream document is auditable against RAH-DOC-005 line-by-line.
- Gaps and indicative ("à valider") items are made visible instead of quietly resolved.

### Negative / Trade-offs
- Slightly more verbose documents (citation overhead) in exchange for traceability.

## Related
- [PRD](../prd/PRD.md), [SRS](../srs/SRS.md) — both structured around this citation convention.
