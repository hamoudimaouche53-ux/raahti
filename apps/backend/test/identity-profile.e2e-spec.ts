import { INestApplication, ValidationPipe } from '@nestjs/common';
import { APP_GUARD, Reflector } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { FavoriteService } from '../src/modules/identity/application/favorite.service';
import { PaymentMethodService } from '../src/modules/identity/application/payment-method.service';
import { UserProfileService } from '../src/modules/identity/application/user-profile.service';
import { VerificationDocumentService } from '../src/modules/identity/application/verification-document.service';
import { Favorite } from '../src/modules/identity/domain/entities/favorite.entity';
import { PaymentMethod } from '../src/modules/identity/domain/entities/payment-method.entity';
import { User } from '../src/modules/identity/domain/entities/user.entity';
import { VerificationDocument } from '../src/modules/identity/domain/entities/verification-document.entity';
import { FAVORITE_REPOSITORY, FavoritePage, FavoriteRepository } from '../src/modules/identity/domain/ports/favorite.repository';
import { PAYMENT_METHOD_REPOSITORY, PaymentMethodRepository } from '../src/modules/identity/domain/ports/payment-method.repository';
import { USER_REPOSITORY, UserRepository } from '../src/modules/identity/domain/ports/user.repository';
import {
  VERIFICATION_DOCUMENT_REPOSITORY,
  VerificationDocumentRepository,
} from '../src/modules/identity/domain/ports/verification-document.repository';
import { JWT_VERIFIER, JwtVerifier } from '../src/modules/identity/infrastructure/auth/jwt-verifier.port';
import { FavoritesController } from '../src/modules/identity/interface/controllers/favorites.controller';
import { PaymentMethodsController } from '../src/modules/identity/interface/controllers/payment-methods.controller';
import { UserProfileController } from '../src/modules/identity/interface/controllers/user-profile.controller';
import { VerificationDocumentsController } from '../src/modules/identity/interface/controllers/verification-documents.controller';
import { JwtAuthGuard } from '../src/modules/identity/interface/guards/jwt-auth.guard';
import { RequireMfaGuard } from '../src/modules/identity/interface/guards/require-mfa.guard';
import { RolesGuard } from '../src/modules/identity/interface/guards/roles.guard';
import { SiteScopeGuard } from '../src/modules/identity/interface/guards/site-scope.guard';
import { HttpExceptionFilter } from '../src/platform/http/http-exception.filter';

/**
 * In-memory fakes standing in for Prisma — this suite exercises the real
 * controllers/services end-to-end over HTTP without a live database (none is
 * provisioned yet — ADR-0016). DB-level guarantees (atomic upsert, unique
 * constraints) are covered separately by the Prisma repository unit tests and
 * documented in prisma/README.md / ADR-0028.
 */
class FakeUserRepository implements UserRepository {
  private readonly byId = new Map<string, User>();

  async findById(id: string) {
    return this.byId.get(id) ?? null;
  }
  async findByEmail(email: string) {
    return [...this.byId.values()].find((u) => u.email === email) ?? null;
  }
  async findByPhone(phone: string) {
    return [...this.byId.values()].find((u) => u.phone === phone) ?? null;
  }
  async save(user: User) {
    this.byId.set(user.id, user);
  }
  async findOrCreate(candidate: User) {
    const existing = this.byId.get(candidate.id);
    if (existing) return existing;
    this.byId.set(candidate.id, candidate);
    return candidate;
  }
}

class FakeVerificationDocumentRepository implements VerificationDocumentRepository {
  async save(_document: VerificationDocument) {}
}

class FakePaymentMethodRepository implements PaymentMethodRepository {
  private readonly items: PaymentMethod[] = [];
  async save(method: PaymentMethod) {
    this.items.push(method);
  }
  async listByUserId(userId: string) {
    return this.items.filter((m) => m.userId === userId);
  }
}

class FakeFavoriteRepository implements FavoriteRepository {
  private readonly items: Favorite[] = [];
  async save(favorite: Favorite) {
    const index = this.items.findIndex((f) => f.id === favorite.id);
    if (index >= 0) {
      this.items[index] = favorite;
    } else {
      this.items.push(favorite);
    }
  }
  async listByUserId(userId: string): Promise<FavoritePage> {
    return { data: this.items.filter((f) => f.userId === userId), nextCursor: null };
  }
  async findById(id: string): Promise<Favorite | null> {
    return this.items.find((f) => f.id === id) ?? null;
  }
  async delete(id: string): Promise<void> {
    const index = this.items.findIndex((f) => f.id === id);
    if (index >= 0) {
      this.items.splice(index, 1);
    }
  }
}

class FakeJwtVerifier implements JwtVerifier {
  async verify(token: string) {
    if (token === 'valid-usager') {
      return { sub: 'u1', email: 'usager@example.com', role: 'usager', exp: 0, iat: 0 } as any;
    }
    if (token === 'valid-other-usager') {
      return { sub: 'u2', email: 'other-usager@example.com', role: 'usager', exp: 0, iat: 0 } as any;
    }
    throw new Error('invalid token');
  }
}

describe('Identity profile endpoints (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [UserProfileController, VerificationDocumentsController, PaymentMethodsController, FavoritesController],
      providers: [
        Reflector,
        UserProfileService,
        VerificationDocumentService,
        PaymentMethodService,
        FavoriteService,
        { provide: JWT_VERIFIER, useClass: FakeJwtVerifier },
        { provide: USER_REPOSITORY, useClass: FakeUserRepository },
        { provide: VERIFICATION_DOCUMENT_REPOSITORY, useClass: FakeVerificationDocumentRepository },
        { provide: PAYMENT_METHOD_REPOSITORY, useClass: FakePaymentMethodRepository },
        { provide: FAVORITE_REPOSITORY, useClass: FakeFavoriteRepository },
        { provide: APP_GUARD, useClass: JwtAuthGuard },
        { provide: APP_GUARD, useClass: RolesGuard },
        { provide: APP_GUARD, useClass: SiteScopeGuard },
        { provide: APP_GUARD, useClass: RequireMfaGuard },
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    app.useGlobalFilters(new HttpExceptionFilter());
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  const auth = () => ({ Authorization: 'Bearer valid-usager' });
  const otherAuth = () => ({ Authorization: 'Bearer valid-other-usager' });

  it('JIT-provisions the user on first GET /users/me', async () => {
    const res = await request(app.getHttpServer()).get('/users/me').set(auth()).expect(200);
    expect(res.body).toEqual(
      expect.objectContaining({ id: 'u1', email: 'usager@example.com', preferredLanguage: 'fr' }),
    );
  });

  it('returns the same id on a second GET (idempotent, not re-provisioned)', async () => {
    const first = await request(app.getHttpServer()).get('/users/me').set(auth()).expect(200);
    const second = await request(app.getHttpServer()).get('/users/me').set(auth()).expect(200);
    expect(second.body.id).toBe(first.body.id);
  });

  it('PATCH updates the language preference and it sticks on subsequent GET', async () => {
    await request(app.getHttpServer()).patch('/users/me').set(auth()).send({ preferredLanguage: 'ar' }).expect(200);
    const res = await request(app.getHttpServer()).get('/users/me').set(auth()).expect(200);
    expect(res.body.preferredLanguage).toBe('ar');
  });

  it('rejects an invalid preferredLanguage value with 400', async () => {
    await request(app.getHttpServer()).patch('/users/me').set(auth()).send({ preferredLanguage: 'en' }).expect(400);
  });

  it('submits a verification document as pending', async () => {
    const res = await request(app.getHttpServer())
      .post('/users/me/verification-documents')
      .set(auth())
      .send({ documentType: 'diabetic_certificate', storageRef: 'storage://doc1' })
      .expect(201);
    expect(res.body.reviewStatus).toBe('pending');
  });

  it('rejects an unknown documentType with 400', async () => {
    await request(app.getHttpServer())
      .post('/users/me/verification-documents')
      .set(auth())
      .send({ documentType: 'passport', storageRef: 'storage://doc1' })
      .expect(400);
  });

  it('creates and lists a payment method with only the tokenized providerRef exposed', async () => {
    const createRes = await request(app.getHttpServer())
      .post('/users/me/payment-methods')
      .set(auth())
      .send({ methodType: 'card', providerToken: 'tok_visa_1' })
      .expect(201);
    expect(createRes.body.providerRef).toBe('tok_visa_1');

    const listRes = await request(app.getHttpServer()).get('/users/me/payment-methods').set(auth()).expect(200);
    expect(listRes.body.data).toEqual(expect.arrayContaining([expect.objectContaining({ providerRef: 'tok_visa_1' })]));
  });

  it('creates and lists a favorite', async () => {
    await request(app.getHttpServer())
      .post('/users/me/favorites')
      .set(auth())
      .send({ stationId: '550e8400-e29b-41d4-a716-446655440000' })
      .expect(201);

    const listRes = await request(app.getHttpServer()).get('/users/me/favorites').set(auth()).expect(200);
    expect(listRes.body.data.length).toBeGreaterThan(0);
    expect(listRes.body).toHaveProperty('nextCursor');
  });

  it('rejects a favorite with both stationId and thirdPartyPlaceId set (XOR invariant)', async () => {
    await request(app.getHttpServer())
      .post('/users/me/favorites')
      .set(auth())
      .send({
        stationId: '550e8400-e29b-41d4-a716-446655440000',
        thirdPartyPlaceId: '6ba7b810-9dad-41d4-80b4-00c04fd430c8',
      })
      .expect(400);
  });

  it('rejects a favorite with neither target set', async () => {
    await request(app.getHttpServer()).post('/users/me/favorites').set(auth()).send({}).expect(400);
  });

  it('deletes a favorite as its owner, removing it from a subsequent list, and 404s on a repeat delete', async () => {
    const createRes = await request(app.getHttpServer())
      .post('/users/me/favorites')
      .set(auth())
      .send({ stationId: '550e8400-e29b-41d4-a716-446655440020' })
      .expect(201);
    const favoriteId: string = createRes.body.id;

    await request(app.getHttpServer()).delete(`/users/me/favorites/${favoriteId}`).set(auth()).expect(204);

    const listRes = await request(app.getHttpServer()).get('/users/me/favorites').set(auth()).expect(200);
    expect(listRes.body.data.map((f: { id: string }) => f.id)).not.toContain(favoriteId);

    await request(app.getHttpServer()).delete(`/users/me/favorites/${favoriteId}`).set(auth()).expect(404);
  });

  it('404s deleting an unknown favorite', async () => {
    await request(app.getHttpServer())
      .delete('/users/me/favorites/6ba7b810-9dad-41d4-80b4-00c04fd430c9')
      .set(auth())
      .expect(404);
  });

  it('PATCHes notifyOnAvailable to true as the owner', async () => {
    const createRes = await request(app.getHttpServer())
      .post('/users/me/favorites')
      .set(auth())
      .send({ stationId: '550e8400-e29b-41d4-a716-446655440021' })
      .expect(201);
    const favoriteId: string = createRes.body.id;
    expect(createRes.body.notifyOnAvailable).toBe(false);

    const patchRes = await request(app.getHttpServer())
      .patch(`/users/me/favorites/${favoriteId}`)
      .set(auth())
      .send({ notifyOnAvailable: true })
      .expect(200);

    expect(patchRes.body.notifyOnAvailable).toBe(true);
  });

  it('403s PATCH/DELETE from a caller who does not own the favorite', async () => {
    const createRes = await request(app.getHttpServer())
      .post('/users/me/favorites')
      .set(auth())
      .send({ stationId: '550e8400-e29b-41d4-a716-446655440022' })
      .expect(201);
    const favoriteId: string = createRes.body.id;

    await request(app.getHttpServer())
      .patch(`/users/me/favorites/${favoriteId}`)
      .set(otherAuth())
      .send({ notifyOnAvailable: true })
      .expect(403);

    await request(app.getHttpServer()).delete(`/users/me/favorites/${favoriteId}`).set(otherAuth()).expect(403);
  });
});
