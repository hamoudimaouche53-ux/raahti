# ADR-0006: IoT Communication Protocol — MQTT

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Engineering team |
| **RAH-DOC-005 reference** | §7 ("MQTT entre passerelle station et Cloud"), §9 (Master Roadmap Phase 9) |

## Context
RAH-DOC-005 §7 explicitly specifies MQTT for station-gateway-to-Cloud communication (this is a stated requirement, not indicative). Master Roadmap Phase 9 confirms an "IoT Platform: MQTT, Devices, Telemetry, Remote Commands" phase.

## Decision
Use **MQTT** as the transport between each station's IoT gateway and the Cloud platform's ingestion service, for both telemetry (station → Cloud) and remote commands (Cloud → station, e.g. unlock orders per FR-PAY-04, alert activation per FR-CLD-02). Webhooks bridge ingestion events into the application backend, per §7 ("webhooks vers le backend applicatif").

## Alternatives Considered
Not applicable — MQTT is an explicit (non-indicative) requirement in RAH-DOC-005 §7; this ADR formally records the decision rather than evaluating alternatives.

## Consequences
### Positive
- Directly satisfies a stated, non-negotiable requirement.
- MQTT's publish/subscribe model and QoS levels fit the low-bandwidth, intermittent-connectivity profile of field station gateways.

### Negative / Trade-offs
- Requires an MQTT broker as new infrastructure (Phase 3/9 concern) alongside Supabase.

## Related
- [C4 Container — Service d'Ingestion IoT](../architecture/c4-container.md), [Domain Model §3 — Station Network (ACL to IoT Gateway)](../architecture/domain-model.md#3-bounded-context-station-network)
