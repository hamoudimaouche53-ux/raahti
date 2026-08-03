# ADR-0010: Diabetic Verification Mechanism — Data Shape Only (Decision Deferred)

| | |
|---|---|
| **Status** | Proposed — intentionally not Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | *(Pending: Product + Health Partners — see RAH-DOC-005 §11)* |
| **RAH-DOC-005 reference** | §2.4, §2.6, §11 |

## Context
RAH-DOC-005 §11 explicitly defers the diabetic-verification mechanism to future discussion with relevant health partners ("Définition détaillée du mécanisme de vérification du statut diabétique... en lien avec les partenaires de santé pertinents"). This ADR exists to prevent Phase 0 documents from silently inventing a clinical verification process that was deliberately left open, while still giving Phase 1/4 engineering a data shape to build against.

## Decision
Phase 0 fixes only the **data shape** of verification (see [ERD §3.9 — VerificationDocument](../erd/erd.md#39-verification-document-new--supports-fr-usr-03)): a user submits a `document_type = diabetic_certificate` file to object storage, which transitions through `pending → approved/rejected`, gating `User.diabeticVerificationStatus`. The **actual clinical/administrative verification process** (who reviews it, what document is acceptable, whether a health-partner API is involved) is **not decided here** and must not be implemented against an assumed process until RAH-DOC-005 §11's health-partner workshop concludes.

## Alternatives Considered
Not applicable — this ADR intentionally scopes down to "data shape only" rather than choosing among verification-process alternatives, which would require information not yet available (PRD OQ1).

## Consequences
### Positive
- Unblocks ERD/domain modeling and backlog estimation without pretending a clinical decision has been made.
- Makes the dependency on the health-partner workshop explicit and trackable (see [Risk Register](../decisions/risk-register.md)).

### Negative / Trade-offs
- The `review_status` workflow (manual admin review, per the current data shape) is a placeholder and may need to change (e.g. to an automated health-partner API check) once §11's workshop concludes — tracked as a risk.

## Related
- [PRD OQ1](../prd/PRD.md#15-open-questions), [ERD §3.9](../erd/erd.md#39-verification-document-new--supports-fr-usr-03), [Risk Register](../decisions/risk-register.md)
