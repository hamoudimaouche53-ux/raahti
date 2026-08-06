import { Injectable, Optional } from '@nestjs/common';
import { LockControlGateway, UnlockOrderResult } from '../../domain/ports/lock-control-gateway';

export interface MockLockControlConfig {
  /** Forces every unlock order to this outcome. Default 'unlocked'. */
  outcome?: 'unlocked' | 'failed';
}

/**
 * ADR-0030 — deterministic, in-memory `LockControlGateway` implementation,
 * mirroring ADR-0014's `MockPaymentGatewayAdapter` precedent. `@Optional()`
 * on the config param — see that adapter's doc comment for why.
 */
@Injectable()
export class MockLockControlAdapter implements LockControlGateway {
  constructor(@Optional() private readonly config: MockLockControlConfig = {}) {}

  async issueUnlockOrder(_params: { cabinId: string; accessSessionId: string }): Promise<UnlockOrderResult> {
    const result = this.config.outcome ?? 'unlocked';
    return { result, acknowledgedAt: result === 'unlocked' ? new Date() : null };
  }
}
