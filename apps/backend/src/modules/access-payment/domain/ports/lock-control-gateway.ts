export const LOCK_CONTROL_GATEWAY = Symbol('LOCK_CONTROL_GATEWAY');

export interface UnlockOrderResult {
  result: 'unlocked' | 'failed';
  acknowledgedAt: Date | null;
}

/**
 * ADR-0030 — Anti-Corruption Layer over the IoT unlock-dispatch path
 * (Sequence Diagrams §1: API -> IoT Ingestion Service -> MQTT publish ->
 * Station Lock). No IoT ingestion service/MQTT broker exists anywhere in
 * this repository yet (Phase 9, out of scope) — this port exists so
 * AccessPaymentModule (V1-critical, EPIC-04), including the R-12
 * refund-on-failure path, can be built and tested now, exactly mirroring
 * ADR-0014's PaymentGateway precedent.
 */
export interface LockControlGateway {
  issueUnlockOrder(params: { cabinId: string; accessSessionId: string }): Promise<UnlockOrderResult>;
}
