# Sequence Diagrams — Critical User Flows

| | |
|---|---|
| **Document ID** | RAH-DOC-025-SEQUENCE-DIAGRAMS |
| **Phase** | Phase 1 — System Architecture |
| **Version** | 1.0 |
| **Related** | [Data Flow Diagrams](./data-flow-diagrams.md) · [Domain Model](./domain-model.md) · [API Architecture](../api/api-architecture.md) |

## 1. QR Scan → Payment → Unlock (incl. failure/refund path)
Implements FR-PAY-01…06, ADR-0014's `PaymentGateway` abstraction, Risk R-11/R-12 mitigation.

```mermaid
sequenceDiagram
    actor U as Usager
    participant App as Mobile App
    participant API as API Backend (AccessPaymentModule)
    participant SN as StationNetworkModule
    participant PG as PaymentGateway Port
    participant Prov as Payment Provider (vendor TBD)
    participant IoT as IoT Ingestion Service
    participant Station as Station Lock

    U->>App: Scan cabin QR code
    App->>API: POST /access-sessions {qrCodeScanned} [Idempotency-Key]
    API->>SN: checkCabinAvailability(cabinId)
    SN-->>API: available
    API-->>App: 201 AccessSession{status: initiated}

    alt Cabin is paid
        App->>API: POST /access-sessions/{id}/payments {paymentMethodId}
        API->>PG: authorize(amount, paymentMethodRef, idempotencyKey)
        PG->>Prov: (adapter-specific call)
        Prov-->>PG: authorization result
        PG-->>API: AuthorizationResult
        API->>PG: capture(authorizationId)
        PG->>Prov: (adapter-specific call)
        Prov-->>PG: capture result
        PG-->>API: CaptureResult
        API->>API: emit PaymentCaptured event
    else Cabin is free
        API->>API: skip payment, proceed directly
    end

    API->>IoT: issue unlock order (internal command)
    IoT->>Station: MQTT publish: unlock
    alt Unlock acknowledged
        Station-->>IoT: unlock ack (MQTT)
        IoT-->>API: unlock confirmed
        API->>SN: CabinOccupancyChanged(occupied)
        API-->>App: 200 Transaction{status: captured}, AccessSession{status: unlocked}
    else Unlock times out / fails
        IoT-->>API: unlock failure (timeout)
        API->>PG: refund(captureId, amount)
        PG->>Prov: (adapter-specific call)
        API-->>App: 502 ProblemDetail{code: UNLOCK_FAILED_REFUNDED}
    end

    U->>Station: Exit, door closes
    Station->>IoT: door-sensor close event (MQTT)
    IoT->>SN: CabinOccupancyChanged(free)
    SN-->>App: Realtime broadcast (all subscribers)
```

## 2. Mode Urgence Activation
Implements FR-EMG-01…03.

```mermaid
sequenceDiagram
    actor U as Usager vérifié diabétique
    participant App as Mobile App
    participant Emg as EmergencyModule
    participant Id as IdentityModule
    participant SN as StationNetworkModule

    U->>App: Tap "Urgence" (bottom nav, one tap)
    App->>Emg: GET /emergency/nearest-facility?lat&lng
    Emg->>Id: getVerificationStatus(userId)
    Id-->>Emg: diabeticVerificationStatus = verified
    Emg->>SN: findNearestAccessibleFacility(lat, lng)  note right: ignores active map filters
    SN-->>Emg: nearest Station/Cabin
    Emg-->>App: 200 {place, nearestCabinId, discountEligible: true}
    App->>U: Show facility + route (FR-PLC-05)
    Note over App,Emg: Discount actually applied later at\nPOST /access-sessions/{id}/payments\n(applyEmergencyDiscount=true)
```

## 3. Real-Time Cabin Status Broadcast
Implements FR-PLC-02, FR-PAY-05, FR-OPS-01.

```mermaid
sequenceDiagram
    participant Station as Station Door Sensor
    participant IoT as IoT Ingestion Service
    participant PG as Postgres (cabin table)
    participant RT as Supabase Realtime
    participant App1 as Mobile App (User A, viewing map)
    participant Ops as Operator Dashboard

    Station->>IoT: MQTT: occupancy changed
    IoT->>PG: UPDATE cabin SET occupancy_status
    PG->>RT: logical replication change event
    par Broadcast to all subscribers
        RT-->>App1: WebSocket: station:{id}:cabins update
        RT-->>Ops: WebSocket: fleet status update
    end
    App1->>App1: Update pin/place-detail UI (<1.5s target, NFR-PERF-01)
```

## 4. Diabetic Verification Submission & Review
Implements FR-USR-03; process step intentionally provider/process-agnostic (ADR-0010).

```mermaid
sequenceDiagram
    actor U as Usager
    participant App as Mobile App
    participant Id as IdentityModule
    participant Storage as Supabase Storage
    actor Admin as Admin (review process TBD)

    U->>App: Select supporting document
    App->>Storage: Upload file
    Storage-->>App: storageRef
    App->>Id: POST /users/me/verification-documents {storageRef}
    Id-->>App: 201 {reviewStatus: pending}
    Note over Id,Admin: Review mechanism intentionally undefined here —\nRAH-DOC-005 §11 defers to health-partner discussion (ADR-0010)
    Admin->>Id: approve/reject (interface TBD)
    Id->>Id: update User.diabeticVerificationStatus
    Id-->>App: status change notification
```

## 5. Operator Alert Triage & Maintenance Scheduling
Implements FR-OPS-02, FR-OPS-03.

```mermaid
sequenceDiagram
    actor Op as Opérateur
    participant Dash as Operator Dashboard
    participant OpsM as OperationsModule
    participant SN as StationNetworkModule

    Note over Dash,OpsM: Alert already raised via telemetry flow (Data Flow Diagram §1)
    Op->>Dash: Open alert queue
    Dash->>OpsM: GET /ops/alerts?status=open
    OpsM-->>Dash: [alerts sorted: fire/SOS > technical > preventive]
    Op->>Dash: Acknowledge alert
    Dash->>OpsM: PATCH /ops/alerts/{id} {status: acknowledged}
    Op->>Dash: Schedule intervention
    Dash->>OpsM: POST /ops/maintenance-interventions {stationId, type, scheduledAt}
    OpsM->>SN: (read) confirm station exists/status
    OpsM-->>Dash: 201 MaintenanceIntervention{status: scheduled}
```

## 6. Offline Map Load & Reconnect Sync
Implements FR-MAP-07, [Offline & Sync Architecture](./offline-sync-architecture.md).

```mermaid
sequenceDiagram
    actor U as Usager
    participant App as Mobile App
    participant Local as Local Cache (Drift/Isar)
    participant API as API Backend

    Note over App: Connectivity lost
    U->>App: Open map
    App->>Local: read cached places
    Local-->>App: last-known places + lastSyncedAt
    App->>U: Render map with "Updated Xm ago" freshness indicator

    Note over App: Connectivity restored
    App->>API: GET /places/nearby (refresh)
    API-->>App: current places
    App->>Local: write-through update
    App->>API: subscribe Supabase Realtime
    API-->>App: incremental updates
    App->>U: Remove freshness indicator, show live status
```

## Completion Status
✅ Complete — six critical flows covering payment/unlock (incl. failure), emergency, real-time broadcast, verification, operations, and offline/sync, each traced to SRS requirements.

**Phase 1 deliverable 6 of 10 — Sequence Diagrams: COMPLETE.**
