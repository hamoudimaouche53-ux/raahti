import { CanActivate, ExecutionContext, Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Request } from 'express';
import { JWT_VERIFIER, JwtVerifier } from '../../infrastructure/auth/jwt-verifier.port';
import { IS_PUBLIC_KEY } from '../../../../platform/auth';

/**
 * AuthN gate (Security Architecture §1). Public routes (`@Public()`, mirrors
 * `security: []` in openapi.yaml) skip verification entirely — the optional-account
 * model (FR-USR-01) means an absent Authorization header is not an error there.
 * Where a header IS sent, it must be valid even on a public route.
 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    @Inject(JWT_VERIFIER) private readonly jwtVerifier: JwtVerifier,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    const request = context.switchToHttp().getRequest<Request>();
    const token = this.extractToken(request);

    if (!token) {
      if (isPublic) {
        return true;
      }
      throw new UnauthorizedException('Missing bearer token.');
    }

    try {
      request.user = await this.jwtVerifier.verify(token);
      return true;
    } catch {
      throw new UnauthorizedException('Invalid or expired token.');
    }
  }

  private extractToken(request: Request): string | undefined {
    const header = request.headers.authorization;
    if (!header?.startsWith('Bearer ')) {
      return undefined;
    }
    return header.slice('Bearer '.length);
  }
}
