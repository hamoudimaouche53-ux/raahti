# Screen Inventory — Epic → Feature → User Story → Screen

| | |
|---|---|
| **Document ID** | RAH-DOC-037-SCREEN-INVENTORY |
| **Phase** | Phase 2 — UI/UX Design System and Product Design |
| **Version** | 1.0 |
| **Related** | [Product Backlog](../backlog/product-backlog.md) · [User Flows](./user-flows.md) · [Wireframes](./wireframes/) · [Assumptions §6](./assumptions-and-open-questions.md#6-fidelity--delivery-method-methodological-note) |

> **45 screens** across 4 surfaces, each traced to at least one backlog User Story (`US-nn.n.n`). "Flagship" = receives an ASCII wireframe + high-fidelity interactive-prototype treatment ([Assumptions §6](./assumptions-and-open-questions.md#6-fidelity--delivery-method-methodological-note)); every screen — flagship or not — receives a full structural wireframe specification in [`wireframes/`](./wireframes/), grouped into 7 files by surface/epic cluster for readability (each screen has its own anchored section within its group file).

## Mobile Application

| Screen ID | Screen Name | Epic | User Stories | Flagship | Wireframe |
|---|---|---|---|---|---|
| SCR-001 | Splash / Launch | — | *(app-shell, not story-specific)* | No | [mobile-map-discovery.md#scr-001](./wireframes/mobile-map-discovery.md#scr-001-splash--launch) |
| SCR-002 | Onboarding — permissions primer | EPIC-01 | US-01.1.1 (supports) | No | [mobile-map-discovery.md#scr-002](./wireframes/mobile-map-discovery.md#scr-002-onboarding--permissions-primer) |
| SCR-003 | Map (Home) | EPIC-01 | US-01.1.1…01.1.7 | **Yes** (light, dark, AR-RTL) | [mobile-map-discovery.md#scr-003](./wireframes/mobile-map-discovery.md#scr-003-map-home-flagship) |
| SCR-004 | Search results / suggestions overlay | EPIC-01 | US-01.1.4 | No | [mobile-map-discovery.md#scr-004](./wireframes/mobile-map-discovery.md#scr-004-search-results--suggestions-overlay) |
| SCR-005 | Place Detail Sheet — Station (RAHETI unit) | EPIC-01 | US-01.2.1…01.2.5 | **Yes** | [mobile-map-discovery.md#scr-005](./wireframes/mobile-map-discovery.md#scr-005-place-detail-sheet--station-flagship) |
| SCR-006 | Place Detail Sheet — Third-Party Place | EPIC-01 | US-01.2.1…01.2.4 | No | [mobile-map-discovery.md#scr-006](./wireframes/mobile-map-discovery.md#scr-006-place-detail-sheet--third-party-place-variant-of-scr-005) |
| SCR-007 | Submit Review | EPIC-05 | US-05.2 | No | [mobile-map-discovery.md#scr-007](./wireframes/mobile-map-discovery.md#scr-007-submit-review) |
| SCR-031 | Offline / Empty / Error States | EPIC-01 | US-01.1.7 | No | [mobile-map-discovery.md#scr-031](./wireframes/mobile-map-discovery.md#scr-031-offline--empty--error-states) |
| SCR-008 | Slatoki Tab (list + Qibla widget) | EPIC-02 | US-02.1.1, 02.1.3, 02.1.4, 02.1.5 | **Yes** | [mobile-slatoki.md#scr-008](./wireframes/mobile-slatoki.md#scr-008-slatoki-tab-list--qibla-widget-flagship) |
| SCR-009 | Qibla Full-Screen | EPIC-02 | US-02.1.2 | **Yes** | [mobile-slatoki.md#scr-009](./wireframes/mobile-slatoki.md#scr-009-qibla-full-screen-flagship) |
| SCR-010 | Slatoki Place Detail (verified mosque / RAHETI tent) | EPIC-02 | US-02.1.4, 02.1.5 | No | [mobile-slatoki.md#scr-010](./wireframes/mobile-slatoki.md#scr-010-slatoki-place-detail) |
| SCR-011 | Emergency Mode Result | EPIC-03 | US-03.1, 03.2 | **Yes** | [mobile-emergency-payment.md#scr-011](./wireframes/mobile-emergency-payment.md#scr-011-emergency-mode-result-flagship) |
| SCR-012 | Emergency Discount Confirmation (in-flow) | EPIC-03 | US-03.3 | No | [mobile-emergency-payment.md#scr-012](./wireframes/mobile-emergency-payment.md#scr-012-emergency-discount-confirmation) |
| SCR-013 | QR Scanner | EPIC-04 | US-04.1 | **Yes** | [mobile-emergency-payment.md#scr-013](./wireframes/mobile-emergency-payment.md#scr-013-qr-scanner-flagship) |
| SCR-014 | Cabin Availability Confirmation | EPIC-04 | US-04.2 | No | [mobile-emergency-payment.md#scr-014](./wireframes/mobile-emergency-payment.md#scr-014-cabin-availability-confirmation) |
| SCR-015 | Payment Method Selection Sheet | EPIC-04 | US-04.3 | **Yes** | [mobile-emergency-payment.md#scr-015](./wireframes/mobile-emergency-payment.md#scr-015-payment-method-selection-sheet-flagship) |
| SCR-016 | Payment Processing (loading) | EPIC-04 | US-04.3 | No | [mobile-emergency-payment.md#scr-016](./wireframes/mobile-emergency-payment.md#scr-016-payment-processing-loading) |
| SCR-017 | Unlock Confirmation / Access Active | EPIC-04 | US-04.4, 04.5 | **Yes** | [mobile-emergency-payment.md#scr-017](./wireframes/mobile-emergency-payment.md#scr-017-unlock-confirmation--access-active-flagship) |
| SCR-018 | Payment Failed / Refund Notice | EPIC-04 | US-04.3 (error path) | No | [mobile-emergency-payment.md#scr-018](./wireframes/mobile-emergency-payment.md#scr-018-payment-failed--refund-notice) |
| SCR-019 | Session Complete / Exit Confirmation | EPIC-04 | US-04.6 | No | [mobile-emergency-payment.md#scr-019](./wireframes/mobile-emergency-payment.md#scr-019-session-complete--exit-confirmation) |
| SCR-020 | Profile / Account Home | EPIC-05 | US-05.1, 05.2 | **Yes** | [mobile-profile-account.md#scr-020](./wireframes/mobile-profile-account.md#scr-020-profile--account-home-flagship) |
| SCR-021 | Visit History | EPIC-05 | US-05.2 | No | [mobile-profile-account.md#scr-021](./wireframes/mobile-profile-account.md#scr-021-visit-history) |
| SCR-022 | Saved Payment Methods | EPIC-05 | US-05.2 | No | [mobile-profile-account.md#scr-022](./wireframes/mobile-profile-account.md#scr-022-saved-payment-methods) |
| SCR-023 | My Reviews | EPIC-05 | US-05.2 | No | [mobile-profile-account.md#scr-023](./wireframes/mobile-profile-account.md#scr-023-my-reviews) |
| SCR-024 | Diabetic Verification Submission | EPIC-05 | US-05.3 | **Yes** | [mobile-profile-account.md#scr-024](./wireframes/mobile-profile-account.md#scr-024-diabetic-verification-submission-flagship) |
| SCR-025 | Diabetic Verification Status | EPIC-05 | US-05.3 | No | [mobile-profile-account.md#scr-025](./wireframes/mobile-profile-account.md#scr-025-diabetic-verification-status) |
| SCR-026 | Favorites List | EPIC-05 | US-05.4 | No | [mobile-profile-account.md#scr-026](./wireframes/mobile-profile-account.md#scr-026-favorites-list) |
| SCR-027 | Notification Settings | EPIC-05 | US-05.4 | No | [mobile-profile-account.md#scr-027](./wireframes/mobile-profile-account.md#scr-027-notification-settings) |
| SCR-028 | Notifications Inbox | EPIC-10 | US-10.3 (surfaced UI) | No | [mobile-profile-account.md#scr-028](./wireframes/mobile-profile-account.md#scr-028-notifications-inbox) |
| SCR-029 | Language & Theme Settings | EPIC-06 | US-06.1, 06.5 | No | [mobile-profile-account.md#scr-029](./wireframes/mobile-profile-account.md#scr-029-language--theme-settings) |
| SCR-030 | Sign In / Sign Up (optional) | EPIC-05 | US-05.1 | No | [mobile-profile-account.md#scr-030](./wireframes/mobile-profile-account.md#scr-030-sign-in--sign-up-optional) |

## Web Platform (Vitrine)

| Screen ID | Screen Name | Epic | User Stories | Flagship | Wireframe |
|---|---|---|---|---|---|
| SCR-032 | Web Landing / Mission | EPIC-07 | US-07.1 | **Yes** | [web-platform.md#scr-032](./wireframes/web-platform.md#scr-032-web-landing--mission-flagship) |
| SCR-033 | Web Station Map | EPIC-07 | US-07.1, 07.2 | No | [web-platform.md#scr-033](./wireframes/web-platform.md#scr-033-web-station-map) |
| SCR-034 | Web Slatoki Section | EPIC-07 | US-07.2 | No | [web-platform.md#scr-034](./wireframes/web-platform.md#scr-034-web-slatoki-section) |
| SCR-035 | Web App Download Section | EPIC-07 | US-07.1, 07.2 | No | [web-platform.md#scr-035](./wireframes/web-platform.md#scr-035-web-app-download-section) |
| SCR-036 | Web Partner Contact | EPIC-07 | US-07.1 | No | [web-platform.md#scr-036](./wireframes/web-platform.md#scr-036-web-partner-contact) |

## Operator Dashboard

| Screen ID | Screen Name | Epic | User Stories | Flagship | Wireframe |
|---|---|---|---|---|---|
| SCR-037 | Fleet Overview | EPIC-08 | US-08.1 | **Yes** | [operator-dashboard.md#scr-037](./wireframes/operator-dashboard.md#scr-037-fleet-overview-flagship) |
| SCR-038 | Alert Queue | EPIC-08 | US-08.2 | No | [operator-dashboard.md#scr-038](./wireframes/operator-dashboard.md#scr-038-alert-queue) |
| SCR-039 | Alert Detail | EPIC-08 | US-08.2 | No | [operator-dashboard.md#scr-039](./wireframes/operator-dashboard.md#scr-039-alert-detail) |
| SCR-040 | Maintenance Scheduling | EPIC-08 | US-08.3 | No | [operator-dashboard.md#scr-040](./wireframes/operator-dashboard.md#scr-040-maintenance-scheduling) |
| SCR-041 | Station Occupancy History | EPIC-08 | US-08.4 | No | [operator-dashboard.md#scr-041](./wireframes/operator-dashboard.md#scr-041-station-occupancy-history) |
| SCR-042 | Role / Access Management | EPIC-08 | US-08.5 | No | [operator-dashboard.md#scr-042](./wireframes/operator-dashboard.md#scr-042-role--access-management) |

## Sponsor Dashboard

| Screen ID | Screen Name | Epic | User Stories | Flagship | Wireframe |
|---|---|---|---|---|---|
| SCR-043 | Sponsor Stats Overview | EPIC-09 | US-09.1, 09.4 | **Yes** | [sponsor-dashboard.md#scr-043](./wireframes/sponsor-dashboard.md#scr-043-sponsor-stats-overview-flagship) |
| SCR-044 | Campaign Report Export | EPIC-09 | US-09.2 | No | [sponsor-dashboard.md#scr-044](./wireframes/sponsor-dashboard.md#scr-044-campaign-report-export) |
| SCR-045 | Sponsored Stations Map | EPIC-09 | US-09.3 | No | [sponsor-dashboard.md#scr-045](./wireframes/sponsor-dashboard.md#scr-045-sponsored-stations-map) |

## Coverage Check

| Epic | Screens | Note |
|---|---|---|
| EPIC-01 Real-Time Map & Discovery | SCR-002 to SCR-006, SCR-031 | |
| EPIC-02 Slatoki | SCR-008, SCR-009, SCR-010 | |
| EPIC-03 Mode Urgence | SCR-011, SCR-012 | |
| EPIC-04 Payment & Unlock Journey | SCR-013 to SCR-019 | |
| EPIC-05 User Profile & Account | SCR-007, SCR-020 to SCR-026, SCR-030 | |
| EPIC-06 Bilingual & Material 3 | SCR-029 (cross-cutting: all screens support FR/AR/EN + theme, per [ADR-0011](../adr/0011-material-design-3-as-design-system.md)/[ADR-0017](../adr/0017-trilingual-support-fr-ar-en.md)) | |
| EPIC-07 Web Platform | SCR-032 to SCR-036 | |
| EPIC-08 Operator Dashboard | SCR-037 to SCR-042 | |
| EPIC-09 Sponsor Dashboard | SCR-043 to SCR-045 | |
| EPIC-10 Cloud Platform & IoT | *(no dedicated screens — backend epic; effects surface via SCR-003 real-time status, SCR-017 unlock, SCR-028 notifications)* | |

Every one of the 52 backlog User Stories with a UI-facing requirement maps to at least one screen above; the few without a direct screen (e.g. US-06.3 "native-authored content," US-10.1/10.2/10.4 backend-only) are process/backend stories with no UI surface by nature, consistent with the [Product Backlog](../backlog/product-backlog.md)'s own story descriptions.

## Completion Status

| Item | Status |
|---|---|
| Every screen traced to Epic + User Story | ✅ Complete |
| Every backlog Epic represented (or explicitly noted as non-UI) | ✅ Complete |
| 15 flagship screens selected covering all UI-bearing epics | ✅ Complete |

**Phase 2 deliverable 10 of 10 — Screen Inventory: COMPLETE** *(produced ahead of deliverables 6–9 since flows/wireframes/prototype key off this table).*
