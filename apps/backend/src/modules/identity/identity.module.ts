import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { FavoriteService } from './application/favorite.service';
import { PaymentMethodService } from './application/payment-method.service';
import { UserProfileService } from './application/user-profile.service';
import { VerificationDocumentService } from './application/verification-document.service';
import { FAVORITE_REPOSITORY } from './domain/ports/favorite.repository';
import { PAYMENT_METHOD_REPOSITORY } from './domain/ports/payment-method.repository';
import { ROLE_REPOSITORY } from './domain/ports/role.repository';
import { USER_REPOSITORY } from './domain/ports/user.repository';
import { VERIFICATION_DOCUMENT_REPOSITORY } from './domain/ports/verification-document.repository';
import { JWT_VERIFIER } from './infrastructure/auth/jwt-verifier.port';
import { SupabaseJwtVerifier } from './infrastructure/auth/supabase-jwt-verifier';
import { PrismaFavoriteRepository } from './infrastructure/prisma-favorite.repository';
import { PrismaPaymentMethodRepository } from './infrastructure/prisma-payment-method.repository';
import { PrismaRoleRepository } from './infrastructure/prisma-role.repository';
import { PrismaUserRepository } from './infrastructure/prisma-user.repository';
import { PrismaVerificationDocumentRepository } from './infrastructure/prisma-verification-document.repository';
import { FavoritesController } from './interface/controllers/favorites.controller';
import { PaymentMethodsController } from './interface/controllers/payment-methods.controller';
import { UserProfileController } from './interface/controllers/user-profile.controller';
import { VerificationDocumentsController } from './interface/controllers/verification-documents.controller';
import { JwtAuthGuard } from './interface/guards/jwt-auth.guard';
import { RequireMfaGuard } from './interface/guards/require-mfa.guard';
import { RolesGuard } from './interface/guards/roles.guard';
import { SiteScopeGuard } from './interface/guards/site-scope.guard';

/**
 * Identity & Access bounded context (Domain Model §2). Pass 1 (Phase 4
 * Implementation Plan §6 item 1): authentication/RBAC guards, wired globally —
 * every route in the application is protected by default; `@Public()` opts out.
 * Pass 2 (§6 item 2): `/users/me*` controllers — profile (with ADR-0028 JIT
 * provisioning), verification documents, payment methods, favorites.
 */
@Module({
  controllers: [
    UserProfileController,
    VerificationDocumentsController,
    PaymentMethodsController,
    FavoritesController,
  ],
  providers: [
    { provide: JWT_VERIFIER, useClass: SupabaseJwtVerifier },
    { provide: USER_REPOSITORY, useClass: PrismaUserRepository },
    { provide: ROLE_REPOSITORY, useClass: PrismaRoleRepository },
    { provide: VERIFICATION_DOCUMENT_REPOSITORY, useClass: PrismaVerificationDocumentRepository },
    { provide: PAYMENT_METHOD_REPOSITORY, useClass: PrismaPaymentMethodRepository },
    { provide: FAVORITE_REPOSITORY, useClass: PrismaFavoriteRepository },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
    { provide: APP_GUARD, useClass: SiteScopeGuard },
    { provide: APP_GUARD, useClass: RequireMfaGuard },
    UserProfileService,
    VerificationDocumentService,
    PaymentMethodService,
    FavoriteService,
  ],
  exports: [JWT_VERIFIER, USER_REPOSITORY, ROLE_REPOSITORY],
})
export class IdentityModule {}
