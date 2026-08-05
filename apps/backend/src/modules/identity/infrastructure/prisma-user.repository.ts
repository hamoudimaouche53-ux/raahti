import { Injectable } from '@nestjs/common';
import { User as PrismaUser } from '@prisma/client';
import { LanguagePreference } from '../../../shared-kernel';
import { PrismaService } from '../../../platform/database/prisma.service';
import { User } from '../domain/entities/user.entity';
import { UserRepository } from '../domain/ports/user.repository';

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
