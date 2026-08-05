import { Injectable } from '@nestjs/common';
import { Prisma, User as PrismaUser } from '@prisma/client';
import { LanguagePreference } from '../../../shared-kernel';
import { PrismaService } from '../../../platform/database/prisma.service';
import { ConflictingContactMethodException, User } from '../domain/entities/user.entity';
import { UserRepository } from '../domain/ports/user.repository';

const UNIQUE_CONSTRAINT_VIOLATION = 'P2002';

@Injectable()
export class PrismaUserRepository implements UserRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string): Promise<User | null> {
    const record = await this.prisma.user.findUnique({ where: { id } });
    return record ? this.toDomain(record) : null;
  }

  async findByEmail(email: string): Promise<User | null> {
    const record = await this.prisma.user.findUnique({ where: { email } });
    return record ? this.toDomain(record) : null;
  }

  async findByPhone(phone: string): Promise<User | null> {
    const record = await this.prisma.user.findUnique({ where: { phone } });
    return record ? this.toDomain(record) : null;
  }

  async save(user: User): Promise<void> {
    await this.prisma.user.upsert({
      where: { id: user.id },
      create: {
        id: user.id,
        email: user.email,
        phone: user.phone,
        preferredLanguage: user.preferredLanguage.code,
        diabeticVerificationStatus: user.diabeticVerificationStatus,
        isActive: user.isActive,
      },
      update: {
        email: user.email,
        phone: user.phone,
        preferredLanguage: user.preferredLanguage.code,
        diabeticVerificationStatus: user.diabeticVerificationStatus,
        isActive: user.isActive,
      },
    });
  }

  async findOrCreate(candidate: User): Promise<User> {
    try {
      const record = await this.prisma.user.upsert({
        where: { id: candidate.id },
        create: {
          id: candidate.id,
          email: candidate.email,
          phone: candidate.phone,
          preferredLanguage: candidate.preferredLanguage.code,
          diabeticVerificationStatus: candidate.diabeticVerificationStatus,
          isActive: candidate.isActive,
        },
        // No-op update: if the row already exists, never overwrite its fields
        // (e.g. a previously-set preferredLanguage) just because it was touched
        // again — see ADR-0028. Atomic under concurrent first-requests.
        update: {},
      });
      return this.toDomain(record);
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === UNIQUE_CONSTRAINT_VIOLATION) {
        throw new ConflictingContactMethodException();
      }
      throw error;
    }
  }

  private toDomain(record: PrismaUser): User {
    return User.create({
      id: record.id,
      email: record.email,
      phone: record.phone,
      preferredLanguage: LanguagePreference.of(record.preferredLanguage),
      diabeticVerificationStatus: record.diabeticVerificationStatus,
      isActive: record.isActive,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });
  }
}
