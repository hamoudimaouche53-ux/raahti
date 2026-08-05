import { VerificationDocumentRepository } from '../domain/ports/verification-document.repository';
import { VerificationDocumentService } from './verification-document.service';

describe('VerificationDocumentService', () => {
  it('submits a document as pending and persists it', async () => {
    const repo: jest.Mocked<VerificationDocumentRepository> = { save: jest.fn() };
    const service = new VerificationDocumentService(repo);

    const document = await service.submit('u1', {
      documentType: 'diabetic_certificate',
      storageRef: 'storage://doc1',
    });

    expect(document.userId).toBe('u1');
    expect(document.reviewStatus).toBe('pending');
    expect(repo.save).toHaveBeenCalledWith(document);
  });
});
