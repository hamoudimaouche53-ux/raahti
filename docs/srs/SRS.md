# Software Requirements Specification (SRS)

| | |
|---|---|
| **Document ID** | RAH-DOC-009-SRS |
| **Phase** | Phase 0 — Analysis |
| **Version** | 1.0 |
| **Status** | Draft for Review |
| **Conformance** | Structured per ISO/IEC/IEEE 29148:2018 conventions |
| **Date** | 2026-07-31 |
| **Source of Truth** | [RAH-DOC-005](../../RAH-DOC-005-specification-plateforme-digitale.md) |
| **Related** | [PRD](../prd/PRD.md) · [Architecture Overview](../architecture/architecture-overview.md) · [ERD](../erd/erd.md) · [Domain Model](../architecture/domain-model.md) · [ADRs](../adr/README.md) |

## 1. Introduction

### 1.1 Purpose
This SRS restates every functional and non-functional requirement in RAH-DOC-005 as discrete, uniquely identified, verifiable requirements (`FR-*` / `NFR-*`), suitable for backlog decomposition (Phase 0 §8), architecture validation (Phase 1), and test-case derivation (Phase 12). It adds no product capability beyond RAH-DOC-005 and the Material Design 3 constraint communicated for Phase 0; see §7 for the full traceability matrix and §9 for gaps explicitly flagged as assumptions.

### 1.2 Scope
Covers the five digital-layer components defined in RAH-DOC-005 §1: Mobile Application, Web Platform, Operator Dashboard, Sponsor Dashboard, Cloud Platform/IoT integration. Physical station hardware requirements are out of scope (owned by RAH-DOC-004).

### 1.3 Definitions, Acronyms
| Term | Definition |
|---|---|
| RAHETI unit | RAHETI-owned physical station (fixed or mobile) with IoT-connected cabins |
| Lieu tiers / third-party place | Non-RAHETI location referenced in-app (mosque, business) with declarative status |
| Slatoki | Women's prayer/ablution feature and physical tent equipment |
| PMR | *Personne à Mobilité Réduite* — reduced-mobility accessible |
| RTL | Right-to-left text layout (Arabic) |
| SSOT | Single source of truth (RAH-DOC-005 for functional scope) |
| M3 | Material Design 3 (Material You) |

### 1.4 Requirement ID Convention
`FR-<MODULE>-<seq>` for functional, `NFR-<CATEGORY>-<seq>` for non-functional. Each requirement cites its RAH-DOC-005 source section in brackets, e.g. `[§2.3]`. Requirements with no RAH-DOC-005 citation originate from the Material 3 instruction and are marked `[NEW]`.

## 2. Overall Description

### 2.1 Product Perspective
RAHATI's digital layer is a distributed system: one Cloud backend serving three client surfaces (mobile app, operator dashboard, sponsor dashboard) plus a public website, integrated with a fleet of IoT-connected physical stations over MQTT. See [Architecture Overview](../architecture/architecture-overview.md) and [C4 Context Diagram](../architecture/c4-context.md).

### 2.2 User Classes
See [PRD §5](../prd/PRD.md#5-target-users--personas) for full persona detail: End user, Slatoki user, Verified diabetic user, Field operator, Sponsor, Web visitor.

### 2.3 Operating Environment
Android and iOS (mobile app, cross-platform — Flutter per [ADR-0002](../adr/0002-mobile-framework-selection.md)); modern evergreen web browsers (website, dashboards); Cloud-hosted backend with regional presence near the Algerian market [§7].

### 2.4 Design & Implementation Constraints
- Clean Architecture, DDD, SOLID, API-First, Offline-First (per Master Roadmap Phase 1 and RAH-DOC-005 §7 indicative stack).
- Material Design 3 as the mandatory UI design system across all surfaces **[NEW]**.
- Native RTL support for Arabic; no production machine translation [§2.7].
- PCI-DSS or local-equivalent compliance for payment processing [§7].

## 3. Functional Requirements — Mobile Application

### 3.1 Real-Time Map [§2.1]
- **FR-MAP-01**: The system shall display the user's current position and all nearby places on a map as the home screen.
- **FR-MAP-02**: Pins shall be color-coded: green (free WC), blue (paid WC), amber (RAHETI mobile unit), magenta (Slatoki), per RAH-DOC-002 §4.2.
- **FR-MAP-03**: Each pin shall be tappable and open the corresponding place detail sheet (§4).
- **FR-MAP-04**: The system shall provide a bilingual (FR/AR) search bar with nearby-place suggestions.
- **FR-MAP-05**: The system shall provide multi-select quick filter chips: All / Free WC / Paid WC / RAHETI Units / Slatoki.
- **FR-MAP-06**: The system shall auto-recenter on the user's position, with a user-toggleable lock/unlock of position tracking.
- **FR-MAP-07**: On loss of network connectivity, the system shall display the last cached set of nearby places with a visible data-freshness indicator.

### 3.2 Place Detail [§2.2]
- **FR-PLC-01**: The place detail view shall show bilingual (FR/AR) name, distance, average rating, and review count.
- **FR-PLC-02**: The place detail view shall show real-time availability status (Free/Occupied) — IoT-sourced for RAHETI units, community/declarative for third-party places.
- **FR-PLC-03**: The place detail view shall show access type (free/paid with displayed tariff) and accepted payment methods.
- **FR-PLC-04**: The place detail view shall show qualification tags: Women ✓, Wudu ✓, PMR, Open/Closed.
- **FR-PLC-05**: The system shall provide a one-tap "Route" action that opens the device's default navigation app.

### 3.3 Slatoki (صلاتكِ) [§2.3]
- **FR-SLK-01**: The bottom navigation bar shall include a dedicated "Slatoki" tab (Map / Slatoki / Emergency / Profile).
- **FR-SLK-02**: The system shall provide a persistently oriented Qibla compass, available as a home-screen widget and in a full-screen mode.
- **FR-SLK-03**: The Slatoki view shall provide filters: Prayer only / Wudu only / Prayer + Wudu.
- **FR-SLK-04**: The system shall visually distinguish verified mosques with confirmed women's sections from generic/unverified spaces.
- **FR-SLK-05**: For RAHETI Slatoki tents, the system shall display deployment status (deployed/folded), capacity (number of mats), and amenities (lighting, privacy curtain).

### 3.4 Mode Urgence [§2.4]
- **FR-EMG-01**: The bottom navigation bar shall provide one-tap access to Mode Urgence with no intermediate screen.
- **FR-EMG-02**: For verified diabetic users, activating Mode Urgence shall immediately geolocate the nearest accessible facility, ignoring any currently active filters.
- **FR-EMG-03**: Verified diabetic users shall receive a 50% discount on paid-WC access, applied at the partner/RAHETI payment step.
- **FR-EMG-04 [constraint]**: Extension of Mode Urgence to additional profiles (elderly, pregnant) is explicitly out of scope for V1 [§2.4]; not to be implemented until scoped in a dedicated product workshop.

### 3.5 Payment & Unlock Journey (RAHETI units) [§2.5]
- **FR-PAY-01**: The system shall allow the user to scan a station-cabin QR code to initiate an access session.
- **FR-PAY-02**: On scan, the system shall identify the cabin and check real-time availability before proceeding.
- **FR-PAY-03**: If the cabin is paid, the system shall trigger payment via saved card, mobile wallet, or subscription; if free, it shall grant direct access.
- **FR-PAY-04**: On payment/access confirmation, the Cloud platform shall issue an unlock order to the station's electronic lock.
- **FR-PAY-05**: The cabin's occupancy status shall update in real time for all app users and on the Operator Dashboard.
- **FR-PAY-06**: On door-sensor-detected closing after exit, the system shall automatically release the cabin's occupied status.

### 3.6 User Profile [§2.6]
- **FR-USR-01**: Account creation shall be optional; core map/discovery features shall not require registration.
- **FR-USR-02**: Registered users shall be able to view visit history, manage saved payment methods, and view/manage submitted reviews.
- **FR-USR-03**: The system shall support an activatable "verified diabetic user" status, granted on supporting-document submission, gating FR-EMG-03.
- **FR-USR-04**: Registered users shall be able to manage favorites and receive availability-follow notifications for selected places.

### 3.7 Bilingual FR/AR [§2.7]
- **FR-I18N-01**: The system shall provide a one-tap language toggle, persisted per user.
- **FR-I18N-02**: All Arabic-language screens shall render with native RTL layout adaptation, not a mirrored LTR layout.
- **FR-I18N-03**: All user-facing content shall be natively authored in each supported language; no machine-translated content in production.

## 4. Functional Requirements — Web Platform [§3]
- **FR-WEB-01**: The website shall present the RAHETI mission, a station map, app download links (Google Play, App Store), and a partner contact point, bilingually (FR/AR).
- **FR-WEB-02**: The website shall include the sections: Station, Carte WC, Slatoki, App, mirroring the existing prototype.
- **FR-WEB-03**: The website shall be optimized for local SEO on terms related to public sanitation, prayer spaces, and water points in Algeria.

## 5. Functional Requirements — Operator Dashboard [§4]
- **FR-OPS-01**: The dashboard shall present a consolidated view of all network stations: battery status, water level, per-cabin occupancy, active alerts.
- **FR-OPS-02**: The dashboard shall present a prioritized alert queue, ordered: fire/SOS → technical anomaly → preventive maintenance (procedures per RAH-DOC-007).
- **FR-OPS-03**: The dashboard shall support scheduling and tracking of maintenance and refill/emptying interventions.
- **FR-OPS-04**: The dashboard shall present per-station occupancy/frequentation history to support redeployment decisions, including Event configurations.
- **FR-OPS-05**: The dashboard shall support role-based access control for multi-site operations teams.

## 6. Functional Requirements — Sponsor Dashboard [§5]
- **FR-SPN-01**: The dashboard shall present per-sponsored-station visibility statistics: estimated frequentation, exposure duration, geographic zone.
- **FR-SPN-02**: The dashboard shall support exportable campaign performance reports, aligned to sponsorship tiers defined in the Detailed Economic Model §3.
- **FR-SPN-03**: The dashboard shall provide a map visualization of a partner's sponsored stations.
- **FR-SPN-04**: Sponsor access shall be strictly read-only and limited to aggregated data; no individual user PII shall be exposed.

## 7. Functional Requirements — Cloud Platform & IoT [§6]
- **FR-CLD-01**: The Cloud platform shall serve as the single aggregation point for all IoT network telemetry (occupancy, tank/battery levels, alerts) per RAH-DOC-004 §8.
- **FR-CLD-02**: The Cloud platform shall orchestrate outbound station commands (unlock, alert activation) triggered by app or dashboard actions.
- **FR-CLD-03**: The Cloud platform shall provide a notification service covering availability status changes, operator alerts, and user payment confirmations.
- **FR-CLD-04**: The Cloud platform shall maintain a complete, immutable log of transactions and access events for audit and user-support purposes.

## 8. Non-Functional Requirements

### 8.1 Performance [§9]
- **NFR-PERF-01**: Map and place-detail responses shall render in under 1.5s under standard mobile network conditions.

### 8.2 Availability & Resilience [§9]
- **NFR-AVAIL-01**: The Cloud platform shall target ≥ 99.5% availability.
- **NFR-AVAIL-02**: The mobile app shall degrade gracefully on backend unavailability, using local cache and offline mode (see FR-MAP-07).

### 8.3 Security & Privacy [§9]
- **NFR-SEC-01**: All data shall be encrypted in transit and at rest.
- **NFR-SEC-02**: Operator and Sponsor dashboards shall require strong authentication.
- **NFR-SEC-03**: Payment processing integrations shall comply with PCI-DSS or an equivalent local standard [§7].
- **NFR-SEC-04**: The platform shall comply with applicable local personal-data-protection regulation for all user profiles.

### 8.4 Accessibility & Design System [§9, NEW]
- **NFR-A11Y-01**: Mobile accessibility shall follow standard mobile best practices: sufficient contrast, adjustable font size, screen-reader compatibility [§9].
- **NFR-A11Y-02 [NEW]**: All UI surfaces shall conform to **WCAG 2.2 Level AA**.
- **NFR-A11Y-03 [NEW]**: All UI surfaces shall be built on **Material Design 3 (Material You)** — components, color system, typography, spacing, elevation, and motion — per [ADR-0011](../adr/0011-material-design-3-as-design-system.md).
- **NFR-A11Y-04 [NEW]**: The platform shall support both light and dark themes using M3 dynamic theming where the target platform supports it.
- **NFR-A11Y-05 [NEW]**: Custom components (Qibla compass, tent-status card, cabin-status indicator, etc.) shall extend or compose M3 primitives rather than replace them.

### 8.5 Internationalization [§2.7]
- **NFR-I18N-01**: The system shall support FR and AR as first-class languages with native RTL layout for Arabic (restates FR-I18N-02 as a system-wide constraint, not only a mobile-app one — applies equally to the website).

## 9. Data Requirements
Full entity/attribute/constraint detail is specified in the [ERD](../erd/erd.md) and [Domain Model](../architecture/domain-model.md), derived from the indicative entity list in RAH-DOC-005 §8 (Station, Cabine, Lieu tiers, Utilisateur, Transaction, Alerte, Sponsor).

## 10. External Interface Requirements
- **IF-01**: Mobile app ↔ Cloud backend via REST API (see [API contracts](../api/), populated in Phase 1) [§7].
- **IF-02**: Station gateway ↔ Cloud via MQTT [§7, §9].
- **IF-03**: Cloud ↔ Mobile navigation app via device-native intent/URL scheme (route action, FR-PLC-05).
- **IF-04**: Cloud ↔ Payment provider(s) via provider SDK/API, provider TBD (see PRD OQ2).

## 11. Traceability Matrix (excerpt — full matrix maintained in backlog)

| Requirement | RAH-DOC-005 Source | PRD Goal |
|---|---|---|
| FR-MAP-01…07 | §2.1 | G1 |
| FR-PLC-01…05 | §2.2 | G1 |
| FR-SLK-01…05 | §2.3 | G2 |
| FR-EMG-01…04 | §2.4 | G3 |
| FR-PAY-01…06 | §2.5 | G4 |
| FR-USR-01…04 | §2.6 | G1, G3 |
| FR-I18N-01…03 | §2.7 | G7 |
| FR-WEB-01…03 | §3 | G1 |
| FR-OPS-01…05 | §4 | G5 |
| FR-SPN-01…04 | §5 | G6 |
| FR-CLD-01…04 | §6 | G1, G4, G5 |
| NFR-A11Y-02…05 | *(NEW — Material 3 instruction)* | G8 |

## 12. Assumptions
- Requirement granularity assumes one backend serving all clients (confirmed by RAH-DOC-005 §6/§7); no requirement implies per-surface backend duplication.
- Where RAH-DOC-005 §7 offers alternatives ("REST ou GraphQL", "React Native ou Flutter"), this SRS does not resolve them — resolution is recorded in the [ADR log](../adr/README.md), not here, to keep functional requirements decision-neutral.

## 13. Open Questions
Same as [PRD §15](../prd/PRD.md#15-open-questions) (OQ1–OQ4); not duplicated here to avoid drift between documents.

## 14. Completion Status

| Item | Status |
|---|---|
| All RAH-DOC-005 functional requirements captured with unique IDs | ✅ Complete |
| Non-functional requirements captured, including Material 3/WCAG 2.2 AA | ✅ Complete |
| Traceability to RAH-DOC-005 and PRD goals | ✅ Complete |
| External interface requirements | ✅ Complete (payment provider TBD, see OQ2) |
| Data requirements delegated to ERD/Domain Model | ✅ Complete (see linked documents) |

**Phase 0 document 2 of 10 — SRS: COMPLETE.**

## Phase 2 Addendum

*(Appended in Phase 2 — does not alter any requirement above; see [ADR-0017](../adr/0017-trilingual-support-fr-ar-en.md) for full rationale and [Assumptions & Open Questions](../design/assumptions-and-open-questions.md#1-baseline-extension-trilingual-support-frareng) for the open item on content-authoring scope.)*

- **NFR-I18N-01 [EXTENDED, Phase 2]**: extends to a third first-class language, **English (EN)**, alongside FR and AR. Arabic remains the only RTL language; French and English are both LTR, so no new layout-direction logic is introduced beyond what NFR-I18N-01 already required.
- **FR-I18N-01…03 [EXTENDED, Phase 2]**: the language toggle (FR-I18N-01) becomes a three-way switch (FR/AR/EN); the native-authoring rule (FR-I18N-03) is assumed to extend to English pending product confirmation (see Assumptions link above).
