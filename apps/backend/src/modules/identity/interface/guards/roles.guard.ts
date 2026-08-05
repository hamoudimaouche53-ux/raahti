import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from '../../../../platform/auth';
import { JwtClaims } from '../../infrastructure/auth/jwt-claims';

/** Application-layer half of the two-layer AuthZ enforcement (Security Architecture §2). */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user: JwtClaims | undefined = request.user;
    if (!user?.role || !requiredRoles.includes(user.role)) {
      throw new ForbiddenException('Insufficient role for this operation.');
    }
    return true;
  }
}
