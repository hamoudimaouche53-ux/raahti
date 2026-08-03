# ADR-0002: Mobile Application Framework — Flutter

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Engineering team |
| **RAH-DOC-005 reference** | §7 (indicative: "type React Native ou Flutter") |

## Context
RAH-DOC-005 §7 leaves the cross-platform mobile framework indicative, naming React Native or Flutter as candidates "à valider avec l'équipe d'ingénierie retenue." The RAHATI Master Roadmap Phase 5 is explicitly titled "Flutter App," committing to a specific choice at the engineering-planning level. The product also now mandates **Material Design 3** as the design system (see [ADR-0011](./0011-material-design-3-as-design-system.md)); Flutter ships first-party, actively maintained Material 3 (`material` library) components, while React Native requires a third-party M3 library with less parity.

## Decision
Use **Flutter** for the RAHATI mobile application (Android + iOS, single codebase).

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| Flutter | First-party Material 3 support; single codebase; strong offline/local-DB ecosystem (drift/isar) for FR-MAP-07 | Larger app binary size; Dart is a smaller talent pool than JS |
| React Native | Larger JS talent pool; code-sharing with a potential React web dashboard | Material 3 support via third-party libraries only; more native-bridge complexity for QR/BLE/lock-unlock flows |

## Consequences
### Positive
- Direct alignment with Master Roadmap Phase 5.
- First-party Material 3 widget set simplifies NFR-A11Y-03/04/05 compliance.
- Strong native RTL support for NFR-I18N-01.

### Negative / Trade-offs
- Backend/web engineers cannot directly contribute to the Dart codebase without ramp-up.

## Related
- [Architecture Overview §4](../architecture/architecture-overview.md#4-technology-stack), [PRD §11.4](../prd/PRD.md#114-design-system--material-design-3-new-constraint), [ADR-0011](./0011-material-design-3-as-design-system.md)
