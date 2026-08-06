import { randomUUID } from 'crypto';
import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../../platform/database/prisma.service';
import { IdempotencyKeyRepository, IdempotencyRecord } from '../../domain/ports/idempotency-key.repository';

/**
 * Chose a dedicated repository (rather than inline Prisma calls in the
 * application layer) for the idempotency store, so it follows the same
 * port/adapter shape as every other repository in this module and stays
 * mockable in `IdempotencyService`'s own unit tests.
 */
@Injectable()
export class PrismaIdempotencyKeyRepository implements IdempotencyKeyRepository {
  constructor(private readonly prisma: PrismaService) {}

  async find(userId: string, key: string, endpoint: string): Promise<IdempotencyRecord | null> {
    const record = await this.prisma.idempotencyKey.findUnique({
      where: { userId_key_endpoint: { userId, key, endpoint } },
    });
    if (!record || record.responseStatus === null) {
      return null;
    }
    return { responseStatus: record.responseStatus, responseBody: record.responseBody };
  }

  async save(userId: string, key: string, endpoint: string, responseStatus: number, responseBody: unknown): Promise<void> {
    await this.prisma.idempotencyKey.upsert({
      where: { userId_key_endpoint: { userId, key, endpoint } },
      create: {
        id: randomUUID(),
        userId,
        key,
        endpoint,
        responseStatus,
        responseBody: responseBody as Prisma.InputJsonValue,
      },
      update: { responseStatus, responseBody: responseBody as Prisma.InputJsonValue },
    });
  }
}
