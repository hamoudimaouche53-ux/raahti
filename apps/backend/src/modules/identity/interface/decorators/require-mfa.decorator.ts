import { SetMetadata } from '@nestjs/common';

export const REQUIRE_MFA_KEY = 'requireMfa';

/**
 * Dashboard "strong authentication" (NFR-SEC-02) — applied to all /ops/* and
 * /sponsors/* routes with role != usager (Security Architecture §1).
 */
export const RequireMfa = (): MethodDecorator & ClassDecorator => SetMetadata(REQUIRE_MFA_KEY, true);
