import { VerificationDocument } from '../entities/verification-document.entity';

export const VERIFICATION_DOCUMENT_REPOSITORY = Symbol('VERIFICATION_DOCUMENT_REPOSITORY');

export interface VerificationDocumentRepository {
  save(document: VerificationDocument): Promise<void>;
}
