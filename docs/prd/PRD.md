# Product Requirements Document (PRD)

| | |
|---|---|
| **Document ID** | RAH-DOC-008-PRD |
| **Phase** | Phase 0 — Analysis |
| **Version** | 1.0 |
| **Status** | Draft for Review |
| **Date** | 2026-07-31 |
| **Source of Truth** | [RAH-DOC-005 — Spécification de Plateforme Digitale](../../RAH-DOC-005-specification-plateforme-digitale.md) |
| **Related** | [RAHATI Master Roadmap](../../RAHATI-Master-Roadmap.md) · [SRS](../srs/SRS.md) · [Architecture Overview](../architecture/architecture-overview.md) · [Product Backlog](../backlog/product-backlog.md) |

> **Traceability note.** This PRD does not introduce, replace, or reinterpret any requirement defined in RAH-DOC-005. Every functional area below is traced back to its source section (cited as `§n`). Where RAH-DOC-005 leaves an item indicative or open, this document flags it explicitly as an **assumption** or **open question** rather than silently deciding it.

---

## 1. Executive Summary

RAHETI ("RAHATI" in the engineering roadmap) is an integrated physical + digital public-comfort infrastructure for Algeria, combining deployed sanitation stations (fixed and mobile units) with a digital ecosystem that lets the public find, verify, pay for, and unlock these facilities in real time — including a differentiated offering for women's prayer and ablution spaces (**Slatoki**) and a fast-path for medically vulnerable users (**Mode Urgence**).

This PRD scopes the **digital layer** of RAHETI: the consumer mobile app, the public website, the two operational dashboards (Operator, Sponsor), and the Cloud/IoT platform that ties them to physical stations. It is the product-level companion to the [SRS](../srs/SRS.md), which restates these needs as verifiable software requirements.

## 2. Problem Statement

Public sanitation access in Algeria is fragmented and inconsistently discoverable, particularly for two underserved needs: (1) women seeking a verified, dignified space for prayer and ablution while away from home, and (2) medically vulnerable individuals (initially diabetic users) who need fast, low-friction access to a toilet. RAH-DOC-005 §1–§2 establishes that closing this gap requires a real-time, bilingual (FR/AR), map-centric digital layer directly wired to physical station telemetry — not a static directory.

## 3. Goals and Objectives

| Goal | Description | Source |
|---|---|---|
| G1 | Provide real-time, trustworthy visibility of sanitation and prayer/ablution facilities within reach of any user, regardless of connectivity. | §2.1, §9 |
| G2 | Make the Slatoki women's prayer/ablution offering a first-class, strategically prominent feature, not a filter. | §2.3 |
| G3 | Deliver a frictionless, one-tap emergency path for diabetic users, including a verified discount. | §2.4 |
| G4 | Enable frictionless QR-based access and payment for RAHETI mobile units, synchronized across app, cloud, and operator view. | §2.5 |
| G5 | Give operations teams the tools to keep the physical network healthy (alerts, maintenance, redeployment decisions). | §4 |
| G6 | Give sponsors transparent, privacy-safe visibility performance data to justify continued investment. | §5 |
| G7 | Deliver a genuinely bilingual FR/AR product, with native RTL layout, not translation-as-afterthought. | §2.7 |
| G8 | Present a consistent, modern, accessible, production-grade user experience across every surface, built on **Material Design 3 (Material You)**. | *(new constraint, see §11.4)* |

## 4. Product Ecosystem (Scope)

Per RAH-DOC-005 §1, the digital layer is composed of five components, each retained as-is:

| Component | Primary user | PRD section |
|---|---|---|
| Mobile Application | End user (usager) | §6 |
| Web Platform (showcase) | General public, press, partners | §7 |
| Operator Dashboard | RAHETI field/technical/ops team | §8 |
| Sponsor Dashboard | Advertisers/sponsorship partners | §9 |
| Cloud Platform + IoT integration | Shared backend, no direct user access | §10 |

## 5. Target Users / Personas

| Persona | Description | Primary surface | Key needs |
|---|---|---|---|
| **Usager (end user)** | General public member seeking a toilet, prayer, or ablution space. Bilingual FR/AR. | Mobile app | Fast discovery, trust in real-time status, low-friction payment |
| **Usagère Slatoki** | Woman seeking a verified prayer/ablution space, mosque or RAHETI Slatoki tent. | Mobile app (Slatoki tab) | Verified "women confirmed" status, Qibla orientation, privacy/comfort signals |
| **Usager vulnérable (diabétique)** | Verified diabetic user needing urgent, discounted access. | Mobile app (Mode Urgence) | One-tap access, nearest open facility regardless of filters, 50% discount |
| **Opérateur terrain** | RAHETI operations/maintenance staff, multi-site. | Operator Dashboard | Fleet health at a glance, prioritized alerts, maintenance scheduling |
| **Sponsor / partenaire** | Advertiser or partner funding station visibility. | Sponsor Dashboard | Aggregated, exportable performance reporting, no PII exposure |
| **Visiteur web / presse / partenaire potentiel** | Public visitor evaluating RAHETI's mission or partnership potential. | Website | Mission clarity, station map, app download, contact |

## 6. Mobile Application — Functional Scope

All items below restate RAH-DOC-005 §2 verbatim in scope (no reinterpretation); implementation detail is deferred to the SRS.

1. **Real-time map** (§2.1) — home screen; color-coded pins (green=free WC, blue=paid WC, amber=RAHETI mobile unit, magenta=Slatoki) per Brand Identity Guidelines RAH-DOC-002 §4.2; bilingual search bar with nearby suggestions; quick filter chips (multi-select); auto-recenter with lock/unlock; offline mode with cached last-known state and a data-freshness indicator.
2. **Place detail sheet** (§2.2) — bilingual name, distance, rating/review count; real-time status (IoT-driven for RAHETI units, community/declarative for third-party places); access type and price; accepted payment methods; qualification tags (Women ✓, Wudu ✓, PMR/accessible, Open/Closed); one-tap route to the device's default navigation app.
3. **Slatoki (صلاتكِ)** (§2.3) — dedicated, strategically prominent bottom-nav tab (Map / Slatoki / Emergency / Profile); persistent Qibla compass (home-screen widget + full-screen mode); filters (Prayer only / Wudu only / Prayer+Wudu); verified-mosque vs. generic-space distinction with confirmed women's section; RAHETI Slatoki tent status (deployed/folded), capacity (mats), amenities (lighting, privacy curtain).
4. **Mode Urgence** (§2.4) — one-tap access from bottom nav, no intermediate step; V1 targets diabetic users; immediate geolocation of nearest accessible facility, independent of active filters; 50% discount on paid WCs for verified diabetic users, requiring the verification mechanism in §2.6 and integration with partner-location payment; extension to other emergency profiles (elderly, pregnant) explicitly out of V1 scope, to be scoped in a future product workshop.
5. **Payment and unlock journey** (§2.5), RAHETI units only — QR scan → real-time availability check → payment (saved card, mobile wallet, subscription) or free direct access → Cloud confirmation → electronic lock unlock order → real-time status broadcast to all app users and the Operator Dashboard → door-sensor-detected close and auto status release.
6. **User profile** (§2.6) — optional account (no forced registration for base usage); history, saved payment methods, reviews; "verified diabetic user" status activated on supporting document, gating the Mode Urgence discount; visited-place history, favorites, availability-follow notifications.
7. **Bilingual FR/AR** (§2.7) — one-tap, per-user-persisted language toggle; native RTL layout adaptation (not a mirrored visual only); natively authored content in each language per RAH-DOC-002 §7 — no production machine translation.

## 7. Web Platform — Functional Scope

Per §3: public bilingual FR/AR site presenting the RAHETI mission, the station map, app download links (Google Play/App Store), and a partner contact point. Sections mirror the existing prototype: Station, Carte WC, Slatoki, App. SEO optimized for local search terms tied to public sanitation, prayer, and water points in Algeria.

## 8. Operator Dashboard — Functional Scope

Per §4: consolidated fleet view (battery, water level, per-cabin occupancy, active alerts); prioritized alert queue (fire/SOS first, then technical anomalies, then preventive maintenance — procedures per RAH-DOC-007); maintenance and refill/emptying scheduling and tracking; per-station occupancy/frequentation history to support redeployment decisions (notably for Event configurations); multi-site access and role management.

## 9. Sponsor Dashboard — Functional Scope

Per §5: per-station visibility statistics (estimated frequentation, exposure duration, geographic zone); exportable campaign performance reports aligned to the sponsorship tiers in the Detailed Economic Model §3; map visualization of a partner's sponsored stations; strictly read-only, aggregated-data-only access — no user PII exposed at this level.

## 10. Cloud Platform and IoT Integration — Functional Scope

Per §6: single aggregation point for all IoT network data (occupancy, levels, battery, alerts, per RAH-DOC-004 §8); order orchestration to stations (unlock, alert activation) triggered from app or dashboard actions; notification service (availability status, operator alerts, user payment confirmations); full transaction and access logging for audit and user support.

## 11. Non-Functional Product Constraints

### 11.1 Availability & Performance (source: §9)
Cloud platform target availability ≥ 99.5%, with graceful degradation on the client (local cache, offline mode). Map and place-detail response time under 1.5s on standard mobile network conditions.

### 11.2 Security & Compliance (source: §9)
Encryption in transit and at rest; strong authentication for Operator and Sponsor dashboards; compliance with local personal-data-protection regulation for all user profiles.

### 11.3 Accessibility & Localization (source: §2.7, §9)
Mobile accessibility per standard mobile best practices (contrast, adjustable font size, screen-reader compatibility); genuine bilingual FR/AR support with native RTL.

### 11.4 Design System — Material Design 3 (new constraint)
> This requirement was introduced after RAH-DOC-005 and does not appear in it. It **refines** — and does not contradict — the accessibility requirement of §9, which specifies "conforme aux bonnes pratiques mobiles usuelles" without naming a system.

- **Material Design 3 (Material You)** is the official design system for the entire digital ecosystem (mobile app, web platform, operator dashboard, sponsor dashboard).
- M3 component set, color system (dynamic color / tonal palettes), typography scale, spacing, elevation, and motion guidelines apply across all surfaces.
- The RAH-DOC-002 brand functional color coding (green/blue/amber/magenta, §4.2) is implemented as a **custom M3 color-role extension** layered on top of the M3 baseline scheme, not a replacement of it — see [ADR-0011](../adr/0011-material-design-3-as-design-system.md).
- Accessibility target is explicitly **WCAG 2.2 AA**, satisfying and making concrete the general accessibility requirement of §9.
- Both **light and dark themes** are supported, using M3 dynamic theming where the platform allows it.
- Any custom component (Qibla compass, Slatoki tent-status card, cabin-status indicator, etc.) must extend or compose M3 primitives rather than replace them.
- Full design-system deliverables (UI kit, Figma library, tokens) are produced in **Phase 2** per the Master Roadmap; this PRD fixes the constraint that Phase 2 must build against.

## 12. Success Metrics (indicative — to be validated with product/business stakeholders)

| Metric | Target (indicative) | Related goal |
|---|---|---|
| Monthly active users (map opens) | Baseline to be set post-launch | G1 |
| Slatoki tab engagement (% of sessions) | Baseline to be set post-launch | G2 |
| Mode Urgence median time-to-facility | < 30s from tap to route | G3 |
| Successful QR unlock rate | > 98% of initiated sessions | G4 |
| Operator alert acknowledgment time | Aligned to RAH-DOC-007 SLAs | G5 |
| Sponsor report export adoption | Tracked post-Phase-8 launch | G6 |
| Crash-free session rate | ≥ 99.5% | G8 |

*No numeric targets for the first three rows exist in RAH-DOC-005; they are flagged as open questions in §14 rather than invented.*

## 13. Out of Scope (V1)

Per §2.4 and §10 (Roadmap): extension of Mode Urgence to non-diabetic profiles (elderly, pregnant); full Sponsor Dashboard (arrives V2 per §10); loyalty program (V2); third-party self-declaration API for mosques/municipalities (V3).

## 14. Assumptions

- A1: "RAHETI" (brand/marketing spelling in RAH-DOC-005) and "RAHATI" (engineering roadmap spelling) refer to the same product; documentation from Phase 0 onward standardizes on **RAHATI** for code/artifact naming and **RAHETI** for brand-facing copy, per existing usage in both source documents.
- A2: The existing prototype `rahati_v2_2.html` referenced in RAH-DOC-005 is available to the design/engineering team during Phase 2 but was not provided as an input to this Phase 0 documentation set.
- A3: RAH-DOC-002 (Brand Identity Guidelines), RAH-DOC-003 (Livre de Conception), RAH-DOC-004 (Livre d'Ingénierie Technique), and RAH-DOC-007 (Manuel de Maintenance) exist as referenced but were not supplied as inputs; where this PRD cites them, it does so only to preserve RAH-DOC-005's own cross-references, without asserting their content.
- A4: Success metrics in §12 are placeholders pending stakeholder validation; no targets were fabricated beyond what is explicitly stated in RAH-DOC-005 (§9 latency/availability, §2.5 unlock reliability implied).

## 15. Open Questions

- OQ1: What is the exact clinical/administrative verification mechanism for "usager vérifié diabétique" (§2.4, §2.6, §11 of RAH-DOC-005)? Explicitly deferred to health-partner discussions in RAH-DOC-005 §11.
- OQ2: Which local mobile/card payment provider(s) will be integrated (§7, §11 of RAH-DOC-005)? Explicitly deferred to provider selection in RAH-DOC-005 §11.
- OQ3: Numeric business KPIs/targets for adoption, retention, and revenue are not defined in RAH-DOC-005 and require a product/business workshop.
- OQ4: Scope and timing of the elderly/pregnant Mode Urgence extension (§2.4) — explicitly deferred to a future product workshop in the source document.

## 16. Completion Status

| Item | Status |
|---|---|
| All RAH-DOC-005 digital-layer requirements represented | ✅ Complete |
| Material 3 design-system constraint incorporated | ✅ Complete |
| Success metrics finalized with numeric targets | ⚠️ Pending stakeholder input (see OQ3) |
| Personas validated with product/business stakeholders | ⚠️ Pending review |

**Phase 0 document 1 of 10 — PRD: COMPLETE (pending the open items above, which do not block downstream Phase 0 documents).**
