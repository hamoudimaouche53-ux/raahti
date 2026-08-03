# Product Backlog — Epics → Features → User Stories → Tasks

| | |
|---|---|
| **Document ID** | RAH-DOC-017-BACKLOG |
| **Phase** | Phase 0 — Analysis |
| **Version** | 1.0 |
| **Status** | Draft for Review |
| **Date** | 2026-07-31 |
| **Related** | [PRD](../prd/PRD.md) · [SRS](../srs/SRS.md) · [Domain Model](../architecture/domain-model.md) |

> Every user story cites the `FR-*`/`NFR-*` requirement(s) it implements (see [SRS](../srs/SRS.md)). Story points are **indicative T-shirt-derived Fibonacci estimates** for Phase-0 planning purposes, to be re-baselined by the delivery team at sprint planning — not commitments.

## Legend
`EPIC-NN` → `FEAT-NN.N` → `US-NN.N.N` → Tasks (implementation-level, non-numbered, per story)

---

## EPIC-01: Real-Time Map & Discovery
*Source: RAH-DOC-005 §2.1, §2.2 · Bounded Contexts: Station Network, Third-Party Places*

### FEAT-01.1 Real-Time Map
| Story | Description | Req | Pts |
|---|---|---|---|
| US-01.1.1 | As an usager, I can see my current position and nearby places on a map on app launch, so I can immediately discover options around me. | FR-MAP-01 | 5 |
| US-01.1.2 | As an usager, I see pins color-coded by type (green/blue/amber/magenta) so I can distinguish place types at a glance. | FR-MAP-02 | 3 |
| US-01.1.3 | As an usager, I can tap a pin to open its place detail sheet. | FR-MAP-03 | 2 |
| US-01.1.4 | As an usager, I can search bilingually (FR/AR) with nearby suggestions. | FR-MAP-04 | 5 |
| US-01.1.5 | As an usager, I can filter the map via multi-select chips (All/Free/Paid/RAHETI/Slatoki). | FR-MAP-05 | 3 |
| US-01.1.6 | As an usager, I can lock/unlock auto-recentering on my position. | FR-MAP-06 | 2 |
| US-01.1.7 | As an usager, I still see my last-known nearby places (with a freshness indicator) when offline. | FR-MAP-07 | 8 |

**Representative Tasks — US-01.1.1**: integrate map SDK (Flutter, M3-styled); implement geolocation permission flow; implement nearby-places query against Station Network + Third-Party Places read model; render pin clustering; unit + widget tests.

**Representative Tasks — US-01.1.7**: implement local cache (Drift/Isar, per [ADR-0008](../adr/0008-offline-first-mobile-sync.md)); implement connectivity listener; implement freshness-indicator UI component (M3 Chip/Badge); integration test for offline/online transition.

### FEAT-01.2 Place Detail
| Story | Description | Req | Pts |
|---|---|---|---|
| US-01.2.1 | As an usager, I see bilingual name, distance, rating, and review count for a place. | FR-PLC-01 | 5 |
| US-01.2.2 | As an usager, I see real-time Free/Occupied status, sourced from IoT for RAHETI units and community-declared for third-party places. | FR-PLC-02 | 8 |
| US-01.2.3 | As an usager, I see access type, tariff, and accepted payment methods. | FR-PLC-03 | 3 |
| US-01.2.4 | As an usager, I see qualification tags (Women ✓, Wudu ✓, PMR, Open/Closed). | FR-PLC-04 | 3 |
| US-01.2.5 | As an usager, I can tap "Route" to open my device's default navigation app. | FR-PLC-05 | 2 |

---

## EPIC-02: Slatoki (صلاتكِ)
*Source: RAH-DOC-005 §2.3 · Bounded Context: Slatoki*

### FEAT-02.1 Slatoki Discovery
| Story | Description | Req | Pts |
|---|---|---|---|
| US-02.1.1 | As an usagère, I have a dedicated Slatoki tab in the bottom nav, distinct from the general map. | FR-SLK-01 | 3 |
| US-02.1.2 | As an usagère, I have a persistent Qibla compass, both as a home-screen widget and full-screen. | FR-SLK-02 | 8 |
| US-02.1.3 | As an usagère, I can filter by Prayer only / Wudu only / Prayer + Wudu. | FR-SLK-03 | 3 |
| US-02.1.4 | As an usagère, I can distinguish verified mosques with confirmed women's sections from generic spaces. | FR-SLK-04 | 5 |
| US-02.1.5 | As an usagère, I see a RAHETI Slatoki tent's deployment status, mat capacity, and amenities. | FR-SLK-05 | 5 |

**Representative Tasks — US-02.1.2**: implement `QiblaDirectionCalculator` domain service (great-circle bearing to Mecca); integrate device compass/magnetometer; build M3-composed compass widget (light/dark); handle magnetometer-unavailable fallback; accuracy unit tests.

---

## EPIC-03: Mode Urgence
*Source: RAH-DOC-005 §2.4 · Bounded Context: Emergency Mode*

| Story | Description | Req | Pts |
|---|---|---|---|
| US-03.1 | As an usager, I can reach Mode Urgence in one tap from the bottom nav, with no intermediate step. | FR-EMG-01 | 2 |
| US-03.2 | As a verified diabetic usager, activating Mode Urgence immediately geolocates the nearest accessible facility, ignoring active filters. | FR-EMG-02 | 5 |
| US-03.3 | As a verified diabetic usager, I receive a 50% discount on paid WC access. | FR-EMG-03 | 8 |
| US-03.4 | *(Explicitly out of V1 — not scheduled)* Extension to elderly/pregnant profiles. | FR-EMG-04 | — |

**Representative Tasks — US-03.3**: implement `EmergencyDiscountPolicy` domain service; wire into Access & Payment's transaction pricing step; require `DiabeticVerificationStatus = verified` guard; E2E test covering unverified-user rejection path.

---

## EPIC-04: Payment & Unlock Journey
*Source: RAH-DOC-005 §2.5 · Bounded Context: Access & Payment*

| Story | Description | Req | Pts |
|---|---|---|---|
| US-04.1 | As an usager, I can scan a cabin's QR code to start an access session. | FR-PAY-01 | 5 |
| US-04.2 | As the system, I check the cabin's real-time availability immediately after identification. | FR-PAY-02 | 3 |
| US-04.3 | As an usager, I am charged via saved card/wallet/subscription if paid, or granted direct access if free. | FR-PAY-03 | 13 |
| US-04.4 | As the system, on confirmation I send an unlock order to the station's electronic lock via the Cloud platform. | FR-PAY-04 | 8 |
| US-04.5 | As an usager or operator, I see the cabin's status update in real time across the app and Operator Dashboard. | FR-PAY-05 | 5 |
| US-04.6 | As the system, I auto-release the cabin's status on door-sensor-detected close. | FR-PAY-06 | 5 |

**Representative Tasks — US-04.3**: integrate payment provider SDK behind `PaymentGateway` ACL port ([Domain Model §6](../architecture/domain-model.md#6-bounded-context-access--payment)); implement `AccessSession`/`Transaction` aggregates; handle payment failure/retry; PCI-DSS-aligned tokenization (no raw PAN storage, [ERD §3.8](../erd/erd.md#38-payment-method-new--supports-26-moyens-de-paiement-enregistrés)); integration tests against provider sandbox.

---

## EPIC-05: User Profile & Account
*Source: RAH-DOC-005 §2.6 · Bounded Context: Identity & Access*

| Story | Description | Req | Pts |
|---|---|---|---|
| US-05.1 | As an usager, I can use core map/discovery features without registering. | FR-USR-01 | 3 |
| US-05.2 | As a registered usager, I can view visit history, manage payment methods, and manage my reviews. | FR-USR-02 | 8 |
| US-05.3 | As an usager, I can submit a supporting document to request "verified diabetic" status. | FR-USR-03 | 8 |
| US-05.4 | As a registered usager, I can manage favorites and receive availability-follow notifications. | FR-USR-04 | 5 |

---

## EPIC-06: Bilingual FR/AR & Material 3 Design System
*Source: RAH-DOC-005 §2.7 + Material 3 constraint (NEW) · Cross-cutting*

| Story | Description | Req | Pts |
|---|---|---|---|
| US-06.1 | As an usager, I can switch language in one tap, and it persists across sessions. | FR-I18N-01 | 3 |
| US-06.2 | As an Arabic-speaking usager, every screen renders with native RTL layout, not a mirrored LTR layout. | FR-I18N-02 | 13 |
| US-06.3 | As a content owner, all copy is natively authored per language, with no machine translation reaching production. | FR-I18N-03 | — (process, not dev) |
| US-06.4 | As any user, every screen is built from Material 3 components with WCAG 2.2 AA contrast/typography/touch-target compliance. | NFR-A11Y-02, NFR-A11Y-03 | 13 |
| US-06.5 | As any user, I can use the app in light or dark theme with correct M3 dynamic theming. | NFR-A11Y-04 | 8 |
| US-06.6 | As a designer/engineer, custom components (Qibla compass, tent-status card, cabin-status indicator) are built by composing M3 primitives. | NFR-A11Y-05 | 5 |

**Representative Tasks — US-06.4**: establish M3 theme (seed color, tonal palettes) extended with RAH-DOC-002 functional colors per [ADR-0011](../adr/0011-material-design-3-as-design-system.md); run automated contrast audit; screen-reader pass (TalkBack/VoiceOver) on all core flows; WCAG 2.2 AA checklist sign-off.

---

## EPIC-07: Web Platform (Vitrine)
*Source: RAH-DOC-005 §3*

| Story | Description | Req | Pts |
|---|---|---|---|
| US-07.1 | As a visiteur, I see the RAHETI mission, station map, download links, and partner contact, bilingually. | FR-WEB-01 | 8 |
| US-07.2 | As a visiteur, I can navigate the Station / Carte WC / Slatoki / App sections mirroring the prototype. | FR-WEB-02 | 8 |
| US-07.3 | As a search engine, I can index the site effectively for local sanitation/prayer/water-point queries. | FR-WEB-03 | 5 |

---

## EPIC-08: Operator Dashboard
*Source: RAH-DOC-005 §4 · Bounded Context: Operations*

| Story | Description | Req | Pts |
|---|---|---|---|
| US-08.1 | As an opérateur, I see a consolidated fleet view (battery, water, occupancy, alerts) across all stations. | FR-OPS-01 | 8 |
| US-08.2 | As an opérateur, I see a prioritized alert queue (fire/SOS → technical → preventive). | FR-OPS-02 | 5 |
| US-08.3 | As an opérateur, I can schedule and track maintenance and refill/emptying interventions. | FR-OPS-03 | 8 |
| US-08.4 | As an opérateur, I see per-station occupancy history to inform redeployment decisions. | FR-OPS-04 | 5 |
| US-08.5 | As an admin, I can manage roles and access for multi-site operations teams. | FR-OPS-05 | 8 |

---

## EPIC-09: Sponsor Dashboard
*Source: RAH-DOC-005 §5 · Bounded Context: Sponsorship (V2 per PRD §13 — included here for backlog completeness)*

| Story | Description | Req | Pts |
|---|---|---|---|
| US-09.1 | As a sponsor, I see per-station visibility stats (frequentation, exposure duration, zone). | FR-SPN-01 | 8 |
| US-09.2 | As a sponsor, I can export campaign performance reports aligned to my sponsorship tier. | FR-SPN-02 | 8 |
| US-09.3 | As a sponsor, I can view my sponsored stations on a map. | FR-SPN-03 | 3 |
| US-09.4 | As a sponsor, my access is strictly read-only and aggregated, with zero user PII exposure. | FR-SPN-04 | 5 |

---

## EPIC-10: Cloud Platform & IoT Integration
*Source: RAH-DOC-005 §6 · Cross-cutting infrastructure*

| Story | Description | Req | Pts |
|---|---|---|---|
| US-10.1 | As the platform, I aggregate all IoT telemetry (occupancy, levels, battery, alerts) at a single point. | FR-CLD-01 | 13 |
| US-10.2 | As the platform, I orchestrate outbound station commands triggered by app/dashboard actions. | FR-CLD-02 | 8 |
| US-10.3 | As the platform, I dispatch notifications for availability, operator alerts, and payment confirmations. | FR-CLD-03 | 8 |
| US-10.4 | As the platform, I maintain a complete, auditable log of transactions and access events. | FR-CLD-04 | 5 |

---

## Backlog Summary

| Epic | Stories | Total Points (indicative) |
|---|---|---|
| EPIC-01 Real-Time Map & Discovery | 12 | 49 |
| EPIC-02 Slatoki | 5 | 24 |
| EPIC-03 Mode Urgence | 3 (+1 deferred) | 15 |
| EPIC-04 Payment & Unlock Journey | 6 | 39 |
| EPIC-05 User Profile & Account | 4 | 24 |
| EPIC-06 Bilingual & Material 3 | 6 | 45 |
| EPIC-07 Web Platform | 3 | 21 |
| EPIC-08 Operator Dashboard | 5 | 34 |
| EPIC-09 Sponsor Dashboard | 4 | 24 |
| EPIC-10 Cloud Platform & IoT | 4 | 34 |
| **Total** | **52 stories** | **~309 pts** |

## Release Alignment (per RAH-DOC-005 §10 and Master Roadmap)

| Release | Epics/Stories in scope |
|---|---|
| V1 | EPIC-01, EPIC-02, EPIC-04, EPIC-05 (US-05.1/05.2/05.4), EPIC-06, part of EPIC-10 |
| V1.1 | EPIC-03 (US-03.1–03.3), US-05.3, notifications (US-04.5-adjacent) |
| V2 | EPIC-09 (full Sponsor Dashboard), Mode Urgence extension (out of backlog per PRD §13 until scoped) |
| V3 | Third-party self-declaration API (not yet backlogged — depends on Phase 1 API design) |

## Assumptions
- Story points are Phase-0 planning-level estimates only, not a delivery-team commitment (per SRS conventions, no fabricated precision beyond what RAH-DOC-005 implies).
- EPIC-09 (Sponsor Dashboard) stories are fully specified now (per RAH-DOC-005 §5) even though V2-scheduled, so the backlog is complete per the Phase 0 mandate; sequencing, not scope, is what shifts to V2.

## Open Questions
- Story-level acceptance criteria beyond the one-line description above will be expanded during Phase 1 sprint-zero grooming with the delivery team.
- See PRD OQ1–OQ4.

## Completion Status

| Item | Status |
|---|---|
| All SRS FR/NFR requirements represented as at least one story | ✅ Complete |
| Epics → Features → Stories → representative Tasks structure | ✅ Complete |
| Release alignment to RAH-DOC-005 §10 roadmap | ✅ Complete |
| Full task breakdown for every single story (not just representative ones) | ⚠️ Deferred to Phase 1 sprint planning — would over-specify implementation detail prematurely at Phase 0 |

**Phase 0 document 8 of 10 — Product Backlog: COMPLETE.**
