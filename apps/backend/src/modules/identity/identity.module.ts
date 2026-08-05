import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { JWT_VERIFIER } from './infrastructure/auth/jwt-verifier.port';
import { SupabaseJwtVerifier } from './infrastructure/auth/supabase-jwt-verifier';
import { PrismaRoleRepository } from './infrastructure/prisma-role.repository';
import { PrismaUserRepository } from './infrastructure/prisma-user.repository';
import { ROLE_REPOSITORY } from './domain/ports/role.repository';
import { USER_REPOSITORY } from './domain/ports/user.repository';
import { JwtAuthGuard } from './interface/guards/jwt-auth.guard';
import { RequireMfaGuard } from './interface/guards/require-mfa.guard';
import { RolesGuard } from './interface/guards/roles.guard';
import { SiteScopeGuard } from './interface/guards/site-scope.guard';

/**
 * Identity & Access bounded context (Domain Model §2). Pass 1 (Phase 4
 * Implementation Plan §6 item 1) wires authentication/RBAC guards globally —
 * every route in the application is protected by default; `@Public()` opts out.
 * Pass 2 adds the `/users/me*` controllers.
 */
@Module({
  providers: [
    { provide: JWT_VERIFIER, useClass: SupabaseJwtVerifier },
    { provide: USER_REPOSITORY, useClass: PrismaUserRepository },
    { provide: ROLE_REPOSITORY, useClass: PrismaRoleRepository },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
    { provide: APP_GUARD, useClass: SiteScopeGuard },
    { provide: APP_GUARD, useClass: RequireMfaGuard },
  ],
  exports: [JWT_VERIFIER, USER_REPOSITORY, ROLE_REPOSITORY],
})
export class IdentityModule {}
