import { Injectable } from '@nestjs/common';
import { Role as PrismaRole } from '@prisma/client';
import { PrismaService } from '../../../platform/database/prisma.service';
import { Role } from '../domain/entities/role.entity';
import { RoleRepository } from '../domain/ports/role.repository';
import { assertRoleCode, RoleCode } from '../domain/value-objects/role-code.vo';

@Injectable()
export class PrismaRoleRepository implements RoleRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findByCode(code: RoleCode): Promise<Role | null> {
    const record = await this.prisma.role.findUnique({ where: { code } });
    return record ? this.toDomain(record) : null;
  }

  async list(): Promise<Role[]> {
    const records = await this.prisma.role.findMany();
    return records.map((record) => this.toDomain(record));
  }

  private toDomain(record: PrismaRole): Role {
    assertRoleCode(record.code);
    return new Role(record.id, record.code, record.labelFr, record.labelAr);
  }
}
