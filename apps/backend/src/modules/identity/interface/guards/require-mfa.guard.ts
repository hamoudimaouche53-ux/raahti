import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtClaims } from '../../infrastructure/auth/jwt-claims';
import { REQUIRE_MFA_KEY } from '../decorators/require-mfa.decorator';

const MFA_VERIFIED_ASSURANCE_LEVEL = 'aal2';

/**
 * Dashboard "strong authentication" (NFR-SEC-02, Security Architecture §1) — requires
 * Supabase's MFA-verified assurance level (`aal2`) on `@RequireMfa()`-decorated routes.
 */
@Injectable()
export class RequireMfaGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiresMfa = this.reflector.getAllAndOverride<boolean>(REQUIRE_MFA_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!requiresMfa) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user: JwtClaims | undefined = request.user;
    if (user?.aal !== MFA_VERIFIED_ASSURANCE_LEVEL) {
      throw new ForbiddenException('MFA verification required for this route.');
    }
    return true;
  }
}
