# Entity-Relationship Diagram (ERD)

| | |
|---|---|
| **Document ID** | RAH-DOC-014-ERD |
| **Phase** | Phase 0 — Analysis |
| **Version** | 1.0 |
| **Status** | Draft for Review |
| **Date** | 2026-07-31 |
| **Source of Truth** | [RAH-DOC-005 §8](../../RAH-DOC-005-specification-plateforme-digitale.md#8-modèle-de-données--entités-principales) (indicative entity list) |
| **Related** | [SRS](../srs/SRS.md) · [Domain Model](../architecture/domain-model.md) · [Architecture Overview](../architecture/architecture-overview.md) |

> RAH-DOC-005 §8 names 7 entities with **indicative** attributes ("Attributs clés (indicatif)"). This ERD keeps every one of those 7 entities and every attribute listed, and completes them with the constraints, keys, and indexes needed for implementation, plus supporting entities required by the functional requirements in the [SRS](../srs/SRS.md) that §8 does not spell out (e.g. `review`, `payment_method`, `telemetry_reading`). Every added entity is justified against a specific `FR-*`/`NFR-*` requirement in the table below.

## 1. Entity Origin Legend

| Marker | Meaning |
|---|---|
| **[SRC]** | Entity named in RAH-DOC-005 §8 |
| **[EXT]** | Attributes on a §8 entity, expanded beyond the indicative list, to satisfy a cited SRS requirement |
| **[NEW]** | Entity not named in §8, added to satisfy a cited SRS requirement |

## 2. Diagram

```mermaid
erDiagram
    ROLE ||--o{ USER_ROLE : "assigned via"
    USER_ACCOUNT ||--o{ USER_ROLE : has
    USER_ACCOUNT ||--o{ PAYMENT_METHOD : saves
    USER_ACCOUNT ||--o{ VERIFICATION_DOCUMENT : submits
    USER_ACCOUNT ||--o{ FAVORITE : bookmarks
    USER_ACCOUNT ||--o{ REVIEW : writes
    USER_ACCOUNT ||--o{ ACCESS_SESSION : initiates
    USER_ACCOUNT ||--o{ TRANSACTION : pays

    STATION ||--o{ CABIN : contains
    STATION ||--o| SLATOKI_TENT : equips
    STATION ||--o{ ALERT : raises
    STATION ||--o{ MAINTENANCE_INTERVENTION : schedules
    STATION ||--o{ SPONSOR_STATION : "sponsored via"
    STATION ||--o{ TELEMETRY_READING : emits
    STATION ||--o{ REVIEW : receives

    CABIN ||--o{ ACCESS_SESSION : "accessed via"
    CABIN ||--o{ TELEMETRY_READING : emits
    CABIN ||--o{ FAVORITE : "favorited as"

    ACCESS_SESSION ||--o| TRANSACTION : generates
    ACCESS_SESSION }o--|| CABIN : targets

    THIRD_PARTY_PLACE ||--o{ THIRD_PARTY_PLACE_TAG : tagged
    TAG ||--o{ THIRD_PARTY_PLACE_TAG : "applied via"
    THIRD_PARTY_PLACE ||--o{ REVIEW : receives
    THIRD_PARTY_PLACE ||--o{ FAVORITE : "favorited as"

    SPONSOR ||--o{ SPONSORSHIP_CAMPAIGN : runs
    SPONSORSHIP_CAMPAIGN ||--o{ SPONSOR_STATION : covers

    USER_ACCOUNT ||--o{ NOTIFICATION : receives
    ALERT ||--o{ NOTIFICATION : triggers
    TRANSACTION ||--o{ NOTIFICATION : confirms

    ROLE {
        uuid id PK
        string code UK "usager|operateur|sponsor|admin"
        string label_fr
        string label_ar
    }

    USER_ACCOUNT {
        uuid id PK
        string email UK "nullable, unique when present"
        string phone UK "nullable, unique when present"
        string preferred_language "fr|ar, default fr"
        string diabetic_verified_status "none|pending|verified|rejected"
        timestamptz created_at
        timestamptz updated_at
        boolean is_active
    }

    USER_ROLE {
        uuid id PK
        uuid user_id FK
        uuid role_id FK
        string site_scope "nullable — multi-site scoping for operateur role"
        timestamptz granted_at
    }

    PAYMENT_METHOD {
        uuid id PK
        uuid user_id FK
        string provider_ref "tokenized reference at payment provider, never raw PAN"
        string method_type "card|mobile_wallet|subscription"
        boolean is_default
        timestamptz created_at
    }

    VERIFICATION_DOCUMENT {
        uuid id PK
        uuid user_id FK
        string document_type "diabetic_certificate"
        string storage_ref "object storage pointer"
        string review_status "pending|approved|rejected"
        uuid reviewed_by FK "nullable, references USER_ACCOUNT (admin)"
        timestamptz submitted_at
        timestamptz reviewed_at "nullable"
    }

    STATION {
        uuid id PK
        string code UK
        string configuration "fixe|mobile|event"
        geography position "GPS point, indexed GIST"
        string status "active|inactive|maintenance"
        int cabin_capacity
        int tank_capacity_liters
        timestamptz installed_at
        timestamptz created_at
        timestamptz updated_at
    }

    CABIN {
        uuid id PK
        uuid station_id FK
        string code
        string type "H|F|Slatoki|PMR"
        string occupancy_status "free|occupied|out_of_service"
        boolean is_paid
        decimal price_amount "nullable when free"
        string price_currency "DZD"
        timestamptz last_status_change_at
    }

    SLATOKI_TENT {
        uuid id PK
        uuid station_id FK UK "one tent config per station"
        string deployment_status "deployed|folded"
        int mat_capacity
        boolean has_lighting
        boolean has_privacy_curtain
        timestamptz last_updated_at
    }

    THIRD_PARTY_PLACE {
        uuid id PK
        string name_fr
        string name_ar
        string place_type "mosque|business|gas_station|other"
        geography position "GPS point, indexed GIST"
        boolean is_free
        decimal price_amount "nullable"
        string price_currency "DZD, nullable"
        string declared_status "open|closed|unknown"
        string status_source "community|owner_declared"
        timestamptz created_at
        timestamptz updated_at
    }

    TAG {
        uuid id PK
        string code UK "women_confirmed|wudu|pmr|prayer|open_now"
        string label_fr
        string label_ar
    }

    THIRD_PARTY_PLACE_TAG {
        uuid third_party_place_id FK
        uuid tag_id FK
        timestamptz applied_at
    }

    ACCESS_SESSION {
        uuid id PK
        uuid cabin_id FK
        uuid user_id FK "nullable — guest QR flow if permitted"
        string status "initiated|payment_pending|unlocked|in_use|completed|cancelled"
        string qr_code_scanned
        timestamptz started_at
        timestamptz unlocked_at "nullable"
        timestamptz closed_at "nullable"
    }

    TRANSACTION {
        uuid id PK
        uuid user_id FK
        uuid access_session_id FK "nullable — not all transactions are cabin access, e.g. subscriptions"
        uuid payment_method_id FK "nullable"
        decimal amount
        string currency "DZD"
        decimal discount_applied "nullable, e.g. 50% Mode Urgence"
        string status "pending|authorized|captured|failed|refunded"
        string provider_ref "external payment provider transaction id"
        timestamptz created_at
    }

    ALERT {
        uuid id PK
        uuid station_id FK
        string type "fire|sos|technical_anomaly|preventive_maintenance"
        string severity "critical|high|medium|low"
        string status "open|acknowledged|in_progress|resolved"
        uuid acknowledged_by FK "nullable, references USER_ACCOUNT (operateur)"
        timestamptz raised_at
        timestamptz resolved_at "nullable"
    }

    MAINTENANCE_INTERVENTION {
        uuid id PK
        uuid station_id FK
        uuid alert_id FK "nullable — may be preventive, not alert-driven"
        string intervention_type "refill|emptying|repair|preventive"
        string status "scheduled|in_progress|completed|cancelled"
        uuid assigned_to FK "references USER_ACCOUNT (operateur)"
        timestamptz scheduled_at
        timestamptz completed_at "nullable"
    }

    TELEMETRY_READING {
        uuid id PK
        uuid station_id FK
        uuid cabin_id FK "nullable — station-level readings have no cabin"
        string metric "battery_level|water_level|door_sensor|occupancy"
        decimal value
        timestamptz recorded_at
    }

    NOTIFICATION {
        uuid id PK
        uuid user_id FK "nullable — operator alerts may target a role, not a user"
        string channel "push|in_app"
        string type "availability|operator_alert|payment_confirmation"
        uuid related_alert_id FK "nullable"
        uuid related_transaction_id FK "nullable"
        string status "queued|sent|delivered|failed"
        timestamptz created_at
    }

    REVIEW {
        uuid id PK
        uuid user_id FK
        uuid station_id FK "nullable — mutually exclusive with third_party_place_id"
        uuid third_party_place_id FK "nullable — mutually exclusive with station_id"
        int rating "1-5"
        string comment "nullable"
        timestamptz created_at
    }

    FAVORITE {
        uuid id PK
        uuid user_id FK
        uuid station_id FK "nullable — mutually exclusive with third_party_place_id"
        uuid third_party_place_id FK "nullable — mutually exclusive with station_id"
        boolean notify_on_available
        timestamptz created_at
    }

    SPONSOR {
        uuid id PK
        string name
        string contact_email
        timestamptz created_at
    }

    SPONSORSHIP_CAMPAIGN {
        uuid id PK
        uuid sponsor_id FK
        string tier "per Detailed Economic Model §3"
        daterange campaign_period
        string status "draft|active|completed|cancelled"
    }

    SPONSOR_STATION {
        uuid sponsorship_campaign_id FK
        uuid station_id FK
        timestamptz linked_at
    }
```

## 3. Entity Reference (attributes, constraints, indexes)

### 3.1 Station **[SRC, EXT]**
Source: §8 — "Identifiant, configuration, position GPS, statut, capacités (cabines, réservoirs)".

| Attribute | Type | Constraint |
|---|---|---|
| id | uuid | PK |
| code | string | UNIQUE, NOT NULL |
| configuration | enum(fixe, mobile, event) | NOT NULL |
| position | geography(Point,4326) | NOT NULL, GIST index (`idx_station_position`) for proximity queries (FR-MAP-01) |
| status | enum(active, inactive, maintenance) | NOT NULL |
| cabin_capacity | int | NOT NULL, ≥ 0 |
| tank_capacity_liters | int | NOT NULL, ≥ 0 |

**Indexes**: `idx_station_position` (GIST, supports FR-MAP nearby queries); `idx_station_status` (btree, supports FR-OPS-01 fleet filtering).

### 3.2 Cabin **[SRC, EXT]**
Source: §8 — "Identifiant, station parente, type (H/F/Slatoki/PMR), statut occupation".

| Attribute | Type | Constraint |
|---|---|---|
| id | uuid | PK |
| station_id | uuid | FK → station.id, NOT NULL, ON DELETE CASCADE |
| code | string | NOT NULL, UNIQUE with station_id |
| type | enum(H, F, Slatoki, PMR) | NOT NULL |
| occupancy_status | enum(free, occupied, out_of_service) | NOT NULL, default `free` |
| is_paid | boolean | NOT NULL |
| price_amount | decimal(10,2) | NULL when `is_paid = false` |

**Indexes**: `idx_cabin_station_id` (FK); `idx_cabin_occupancy_status` (supports FR-PLC-02 real-time status).

### 3.3 Slatoki Tent **[NEW]** — supports FR-SLK-05
One-to-one with a mobile station carrying Slatoki equipment.

| Attribute | Type | Constraint |
|---|---|---|
| id | uuid | PK |
| station_id | uuid | FK → station.id, UNIQUE, NOT NULL |
| deployment_status | enum(deployed, folded) | NOT NULL |
| mat_capacity | int | NOT NULL, ≥ 0 |
| has_lighting | boolean | NOT NULL |
| has_privacy_curtain | boolean | NOT NULL |

### 3.4 Third-Party Place **[SRC, EXT]**
Source: §8 — "Identifiant, nom, type (mosquée/commerce/station-service), tags, note moyenne".

| Attribute | Type | Constraint |
|---|---|---|
| id | uuid | PK |
| name_fr / name_ar | string | NOT NULL (native content per NFR-I18N) |
| place_type | enum(mosque, business, gas_station, other) | NOT NULL |
| position | geography(Point,4326) | NOT NULL, GIST index |
| declared_status | enum(open, closed, unknown) | NOT NULL |
| status_source | enum(community, owner_declared) | NOT NULL |

**Note**: `note moyenne` (average rating) is a **derived/computed value** from `REVIEW`, not a stored column, to avoid update anomalies — computed via materialized view or application-layer aggregation.

**Indexes**: `idx_place_position` (GIST); `idx_place_type`.

### 3.5 Tag / Third-Party Place Tag **[NEW]** — supports FR-PLC-04, RAH-DOC-005 §2.1/§2.2 "tags"
Lookup table + junction, since RAH-DOC-005 identifies specific tag values (Femmes ✓, Wudu ✓, PMR) without specifying persistence. Modeled as a lookup table for extensibility toward the V3 roadmap item (§10) "auto-déclaration de lieux" by third parties, which will need to add tags without schema changes.

### 3.6 User Account **[SRC, EXT]**
Source: §8 — "Identifiant, préférence de langue, statut vérifié, moyens de paiement, favoris".

| Attribute | Type | Constraint |
|---|---|---|
| id | uuid | PK |
| email | string | UNIQUE (nullable — optional account, FR-USR-01) |
| phone | string | UNIQUE (nullable) |
| preferred_language | enum(fr, ar) | NOT NULL, default `fr` |
| diabetic_verified_status | enum(none, pending, verified, rejected) | NOT NULL, default `none` (FR-USR-03, FR-EMG-03) |

**Constraint**: CHECK (`email IS NOT NULL OR phone IS NOT NULL`) once an account is created (guest usage per FR-USR-01 requires no row at all).
**Indexes**: `idx_user_email`, `idx_user_phone` (both partial unique, `WHERE ... IS NOT NULL`).

> **Phase 2 addendum** *(additive, does not alter the row above)*: `preferred_language` extends to `enum(fr, ar, en)` per [ADR-0017](../adr/0017-trilingual-support-fr-ar-en.md). No other attribute changes.

### 3.7 Role / User Role **[NEW]** — supports FR-OPS-05, NFR-SEC-02
Role codes: `usager`, `operateur`, `sponsor`, `admin`. `user_role.site_scope` supports §4's "gestion des accès et rôles pour les équipes multi-sites" without requiring a full separate multi-tenancy model at Phase 0.

### 3.8 Payment Method **[NEW]** — supports §2.6 "moyens de paiement enregistrés"
Stores only a tokenized `provider_ref` from the payment provider (NFR-SEC-03, PCI-DSS alignment) — **no raw card data is persisted**.

### 3.9 Verification Document **[NEW]** — supports FR-USR-03
Backs the "sur justificatif" (supporting document) language in RAH-DOC-005 §2.6. `review_status` and `reviewed_by` support an administrative approval workflow, since RAH-DOC-005 §11 explicitly defers the verification *mechanism* to health-partner discussions (PRD OQ1) — this table only models the *data shape* of that workflow, not the clinical verification logic itself.

### 3.10 Access Session / Transaction **[SRC, EXT]**
`ACCESS_SESSION` models RAH-DOC-005 §2.5 steps 1–3 (scan → availability check → payment-or-direct-access) as a distinct lifecycle from `TRANSACTION` **[SRC]** (§8 — "Identifiant, utilisateur, cabine/lieu, montant, statut, horodatage"), because a free-access session produces no transaction row, while a subscription transaction may exist without a specific access session. `transaction.discount_applied` persists the Mode Urgence 50% discount (FR-EMG-03).

**Indexes**: `idx_access_session_cabin_status` (supports real-time cabin status queries, FR-PAY-05); `idx_transaction_user_id`.

### 3.11 Alert **[SRC, EXT]**
Source: §8 — "Identifiant, station, type, sévérité, statut de traitement". `type` enum values directly mirror the FR-OPS-02 priority order (fire/SOS → technical_anomaly → preventive_maintenance).

**Indexes**: `idx_alert_station_status`; `idx_alert_severity_status` (supports the prioritized queue of FR-OPS-02).

### 3.12 Maintenance Intervention **[NEW]** — supports FR-OPS-03
Optionally linked to the `Alert` that triggered it; may also be scheduled preventively with no triggering alert.

### 3.13 Telemetry Reading **[NEW]** — supports FR-CLD-01, §8 "capteurs"
High-volume, append-only, time-series-shaped table — physically stored in the time-series database (see [ADR-0004](../adr/0004-database-strategy.md)), logically documented here for completeness. Partitioned by `recorded_at` in the physical implementation (Phase 1 concern).

### 3.14 Notification **[NEW]** — supports FR-CLD-03
Log of every notification dispatched, linking back to its trigger (`Alert` or `Transaction`) for auditability (NFR aligned with §6 "journalisation complète").

### 3.15 Review **[NEW]** — supports FR-PLC-01
Polymorphic target via mutually exclusive nullable FKs (`station_id` XOR `third_party_place_id`), enforced by a CHECK constraint: exactly one of the two must be non-null.

### 3.16 Favorite **[NEW]** — supports FR-USR-04
Same polymorphic pattern as `Review`. `notify_on_available` subsumes the "notifications de disponibilité pour un lieu suivi" requirement (§2.6) without a separate subscription table.

### 3.17 Sponsor / Sponsorship Campaign / Sponsor Station **[SRC, EXT]**
Source: §8 — "Identifiant, stations associées, palier, période de campagne". Modeled as three tables rather than one because a sponsor may run multiple campaigns over time, each with its own tier and period and its own set of associated stations (§5 "paliers de sponsoring" plural, Detailed Economic Model §3).

## 4. Referential Integrity Summary

| Relationship | Cardinality | On Delete |
|---|---|---|
| Station → Cabin | 1:N | CASCADE |
| Station → Slatoki Tent | 1:0..1 | CASCADE |
| Station → Alert | 1:N | RESTRICT (preserve audit trail) |
| Station → Maintenance Intervention | 1:N | RESTRICT |
| Station → Telemetry Reading | 1:N | RESTRICT (time-series retention policy governs, not FK cascade) |
| Cabin → Access Session | 1:N | RESTRICT |
| Access Session → Transaction | 1:0..1 | RESTRICT |
| User Account → Transaction | 1:N | RESTRICT |
| User Account → User Role | 1:N | CASCADE |
| Third-Party Place ↔ Tag | M:N via Third Party Place Tag | CASCADE |
| Sponsor → Sponsorship Campaign | 1:N | CASCADE |
| Sponsorship Campaign ↔ Station | M:N via Sponsor Station | CASCADE |

## 5. Indexing Strategy Summary

| Index | Table | Purpose |
|---|---|---|
| GIST spatial index | station.position, third_party_place.position | Nearby-place queries (FR-MAP-01), sub-1.5s target (NFR-PERF-01) |
| Composite (station_id, occupancy_status) | cabin | Real-time availability lookups (FR-PLC-02, FR-PAY-02) |
| Composite (severity, status) | alert | Prioritized operator alert queue (FR-OPS-02) |
| Partial unique (email), (phone) | user_account | Optional-registration uniqueness without forcing NOT NULL |
| (recorded_at) partition key | telemetry_reading | Time-series write/query performance at IoT scale |

## 6. Assumptions
- Average rating (`note moyenne`) and review count are computed, not stored, to avoid write-amplification and staleness — flagged as an implementation detail, not a requirement change.
- `access_session` is introduced to cleanly separate "physical unlock lifecycle" from "payment record," since RAH-DOC-005 §2.5 describes a 6-step flow where payment is conditional — this does not alter the `Transaction` entity's attributes as listed in §8, only adds an optional relationship to it.
- Guest (unauthenticated) QR access is assumed possible for **free** cabins only, consistent with §2.6 ("l'usage de base ne nécessite pas d'inscription obligatoire"); paid access requires an account to attach a payment method. To be confirmed in Phase 1.

## 7. Open Questions
- OQ7: Should guest (non-account) users be able to pay via a one-off provider checkout without creating a `user_account` row? Affects whether `access_session.user_id` and `transaction.user_id` should be nullable in the final schema. Not addressed in RAH-DOC-005.
- See also PRD OQ1 (diabetic verification mechanism, affects `verification_document.review_status` workflow detail) and OQ2 (payment provider, affects `payment_method.provider_ref` format).

## 8. Completion Status

| Item | Status |
|---|---|
| All 7 RAH-DOC-005 §8 entities modeled with full attributes | ✅ Complete |
| Supporting entities added and justified against SRS requirements | ✅ Complete |
| Constraints, keys, indexes specified | ✅ Complete |
| Referential integrity rules specified | ✅ Complete |
| Physical partitioning/time-series strategy | ⚠️ Deferred to Phase 1 (depends on OQ6, time-series store choice) |

**Phase 0 document 5 of 10 — ERD: COMPLETE.**
