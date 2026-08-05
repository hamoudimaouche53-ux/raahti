import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../platform/database/prisma.service';
import { VerificationDocument } from '../domain/entities/verification-document.entity';
import { VerificationDocumentRepository } from '../domain/ports/verification-document.repository';

@Injectable()
export class PrismaVerificationDocumentRepository implements VerificationDocumentRepository {
  constructor(private readonly prisma: PrismaService) {}

  async save(document: VerificationDocument): Promise<void> {
    await this.prisma.verificationDocument.upsert({
      where: { id: document.id },
      create: {
        id: document.id,
        userId: document.userId,
        documentType: document.documentType,
        storageRef: document.storageRef,
        reviewStatus: document.reviewStatus,
        reviewedAt: document.reviewedAt,
      },
      update: {
        reviewStatus: document.reviewStatus,
        reviewedAt: document.reviewedAt,
      },
    });
  }
}
