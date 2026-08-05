import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { JwtClaims } from '../../infrastructure/auth/jwt-claims';

/**
 * Multi-site scoping for the `operateur` role (RAH-DOC-005 §4, ERD §3.7,
 * Security Architecture §2). Compares the JWT's `site_scope` claim against the
 * `:siteId` route param. Roles other than `operateur` are not site-scoped and
 * pass through unchecked — enforcing that is RolesGuard's job, applied together.
 */
@Injectable()
export class SiteScopeGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user: JwtClaims | undefined = request.user;

    if (user?.role !== 'operateur') {
      return true;
    }

    const requestedSiteId = request.params?.siteId;
    if (!requestedSiteId) {
      return true;
    }

    if (user.site_scope !== requestedSiteId) {
      throw new ForbiddenException('Operator is not scoped to this site.');
    }
    return true;
  }
}
