import { Inject, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { VerificationDocument } from '../domain/entities/verification-document.entity';
import {
  VERIFICATION_DOCUMENT_REPOSITORY,
  VerificationDocumentRepository,
} from '../domain/ports/verification-document.repository';

@Injectable()
export class VerificationDocumentService {
  constructor(
    @Inject(VERIFICATION_DOCUMENT_REPOSITORY)
    private readonly verificationDocumentRepository: VerificationDocumentRepository,
  ) {}

  /** POST /users/me/verification-documents (FR-USR-03). Data shape only — see ADR-0010. */
  async submit(userId: string, params: { documentType: string; storageRef: string }): Promise<VerificationDocument> {
    const document = VerificationDocument.submit({
      id: randomUUID(),
      userId,
      documentType: params.documentType,
      storageRef: params.storageRef,
    });
    await this.verificationDocumentRepository.save(document);
    return document;
  }
}
