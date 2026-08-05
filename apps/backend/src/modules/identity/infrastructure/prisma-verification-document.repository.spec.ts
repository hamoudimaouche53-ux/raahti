import { VerificationDocument } from '../domain/entities/verification-document.entity';
import { PrismaVerificationDocumentRepository } from './prisma-verification-document.repository';

function createPrismaMock() {
  return { verificationDocument: { upsert: jest.fn() } } as any;
}

describe('PrismaVerificationDocumentRepository', () => {
  it('upserts a submitted document', async () => {
    const prisma = createPrismaMock();
    const repo = new PrismaVerificationDocumentRepository(prisma);
    const document = VerificationDocument.submit({
      id: 'd1',
      userId: 'u1',
      documentType: 'diabetic_certificate',
      storageRef: 'storage://doc1',
    });

    await repo.save(document);

    expect(prisma.verificationDocument.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'd1' },
        create: expect.objectContaining({ id: 'd1', userId: 'u1', reviewStatus: 'pending' }),
        update: expect.objectContaining({ reviewStatus: 'pending' }),
      }),
    );
  });
});
