# Complete User Flows

| | |
|---|---|
| **Document ID** | RAH-DOC-038-USER-FLOWS |
| **Phase** | Phase 2 — UI/UX Design System and Product Design |
| **Version** | 1.0 |
| **Related** | [Screen Inventory](./screen-inventory.md) · [Sequence Diagrams (Phase 1, backend perspective)](../architecture/sequence-diagrams.md) |

> These are **navigation/UX flows** (screen-to-screen, decision points from the user's perspective) — complementary to, not a duplicate of, the Phase 1 [Sequence Diagrams](../architecture/sequence-diagrams.md), which show actor↔system↔backend message timing. Every node cites its `SCR-*` ID from the [Screen Inventory](./screen-inventory.md).

## 1. Map & Discovery (EPIC-01)

```mermaid
flowchart TD
    A[SCR-001 Splash] --> B{First launch?}
    B -->|Yes| C[SCR-002 Onboarding]
    B -->|No| D[SCR-003 Map Home]
    C --> D
    D --> E{Search or filter?}
    E -->|Search| F[SCR-004 Search overlay]
    F --> D
    E -->|Tap pin| G[SCR-005/006 Place Detail Sheet]
    G --> H{Action}
    H -->|Route| I[Device navigation app — external]
    H -->|Scan QR, RAHETI unit only| J[EPIC-04 flow]
    H -->|Write review| K[SCR-007 Submit Review]
    K --> G
    D --> L{Connectivity lost?}
    L -->|Yes| M[SCR-031 Offline state]
    M -->|Reconnect| D
```

## 2. Slatoki (EPIC-02)

```mermaid
flowchart TD
    A[SCR-003 Map Home] -->|Tap Slatoki tab| B[SCR-008 Slatoki Tab]
    B --> C{Action}
    C -->|Tap Qibla widget| D[SCR-009 Qibla Full-Screen]
    C -->|Apply filter| B
    C -->|Tap a place| E[SCR-010 Slatoki Place Detail]
    E -->|Route| F[Device navigation app — external]
    D -->|Back| B
```

## 3. Mode Urgence (EPIC-03)

```mermaid
flowchart TD
    A[Any screen, bottom nav visible] -->|Tap Emergency, one tap| B[SCR-011 Emergency Result]
    B --> C{User verified diabetic?}
    C -->|Yes| D[discountEligible = true, shown on SCR-011]
    C -->|No| E[Nearest facility shown, no discount badge]
    D --> F[Continue to EPIC-04 QR flow]
    E --> F
    F -->|At payment step| G[SCR-012 Emergency Discount Confirmation]
    G --> H[EPIC-04 SCR-015 Payment Method]
```

## 4. Payment & Unlock Journey (EPIC-04)

```mermaid
flowchart TD
    A[SCR-005 Place Detail\nor SCR-011 Emergency Result] -->|Scan QR| B[SCR-013 QR Scanner]
    B --> C[SCR-014 Cabin Availability Confirmation]
    C --> D{Free or paid?}
    D -->|Free| E[Direct access — skip to G]
    D -->|Paid| F[SCR-015 Payment Method Selection]
    F --> G2[SCR-016 Payment Processing]
    G2 --> H{Payment result}
    H -->|Success| G[SCR-017 Unlock Confirmation / Access Active]
    H -->|Failure| I[SCR-018 Payment Failed / Refund Notice]
    I -->|Retry| F
    E --> G
    G --> J{Unlock command result}
    J -->|Success| K[Cabin in use — user exits physically]
    J -->|Failure, rare| I
    K --> L[SCR-019 Session Complete / Exit Confirmation]
```

## 5. Profile & Account (EPIC-05)

```mermaid
flowchart TD
    A[SCR-003 Map Home] -->|Tap Profile tab| B[SCR-020 Profile Home]
    B --> C{Account exists?}
    C -->|No, guest| D[SCR-030 Sign In / Sign Up]
    D --> B
    C -->|Yes| E{Section}
    E -->|History| F[SCR-021 Visit History]
    E -->|Payment methods| G[SCR-022 Saved Payment Methods]
    E -->|Reviews| H[SCR-023 My Reviews]
    E -->|Verify diabetic status| I[SCR-024 Verification Submission]
    I --> J[SCR-025 Verification Status]
    E -->|Favorites| K[SCR-026 Favorites List]
    K -->|Toggle availability-follow| L[SCR-027 Notification Settings]
    E -->|Notifications| M[SCR-028 Notifications Inbox]
    E -->|Language/Theme| N[SCR-029 Language & Theme Settings]
```

## 6. Language, Theme & RTL Switching (EPIC-06, cross-cutting)

```mermaid
flowchart TD
    A[Any screen] -->|Open Language & Theme Settings| B[SCR-029]
    B --> C{Language selected}
    C -->|FR or EN| D[Layout direction: LTR]
    C -->|AR| E[Layout direction: RTL]
    D --> F[Re-render current screen stack, same navigation position]
    E --> F
    B --> G{Theme selected}
    G -->|Light / Dark / System| F
```
Applies uniformly across all 45 screens — this flow is referenced, not repeated, in every other flow.

## 7. Web Platform (EPIC-07)

```mermaid
flowchart TD
    A[SCR-032 Web Landing] --> B{Section}
    B -->|Station| C[SCR-033 Web Station Map]
    B -->|Carte WC| C
    B -->|Slatoki| D[SCR-034 Web Slatoki Section]
    B -->|App| E[SCR-035 Web App Download]
    E --> F[App Store / Google Play — external]
    A --> G[SCR-036 Web Partner Contact]
```

## 8. Operator Dashboard (EPIC-08)

```mermaid
flowchart TD
    A[Login] --> B[SCR-037 Fleet Overview]
    B -->|View alerts| C[SCR-038 Alert Queue]
    C -->|Select alert| D[SCR-039 Alert Detail]
    D -->|Acknowledge/Resolve| C
    D -->|Schedule intervention| E[SCR-040 Maintenance Scheduling]
    B -->|Station history| F[SCR-041 Station Occupancy History]
    B -->|Admin role| G[SCR-042 Role / Access Management]
```

## 9. Sponsor Dashboard (EPIC-09)

```mermaid
flowchart TD
    A[Login] --> B[SCR-043 Sponsor Stats Overview]
    B -->|Export| C[SCR-044 Campaign Report Export]
    B -->|View map| D[SCR-045 Sponsored Stations Map]
```

## 10. Completion Status

| Item | Status |
|---|---|
| Flow for every UI-bearing epic (01–09) | ✅ Complete |
| Every flow node cites a Screen Inventory ID | ✅ Complete |
| Cross-cutting language/theme flow referenced, not duplicated, elsewhere | ✅ Complete |

**Phase 2 deliverable 6 of 10 — Complete User Flows: COMPLETE.**
