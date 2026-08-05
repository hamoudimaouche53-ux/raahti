import { PrismaThirdPartyPlaceRepository } from './prisma-third-party-place.repository';

function createPrismaMock() {
  return {
    $queryRaw: jest.fn(),
    thirdPartyPlaceTag: { findMany: jest.fn().mockResolvedValue([]) },
  } as any;
}

const PLACE_ROW = {
  id: 'p1',
  name_fr: 'Mosquée Al-Fath',
  name_ar: 'مسجد الفتح',
  place_type: 'mosque',
  is_free: true,
  price_amount: null,
  price_currency: null,
  declared_status: 'open',
  status_source: 'community',
  created_at: new Date('2026-01-01'),
  updated_at: new Date('2026-01-01'),
  lat: 36.75,
  lng: 3.05,
};

describe('PrismaThirdPartyPlaceRepository', () => {
  it('returns null when no place row is found', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([]);
    const repo = new PrismaThirdPartyPlaceRepository(prisma);

    expect(await repo.findById('missing')).toBeNull();
  });

  it('maps a place row + tags into the entity', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([PLACE_ROW]);
    prisma.thirdPartyPlaceTag.findMany.mockResolvedValue([
      { tag: { code: 'women_confirmed' } },
      { tag: { code: 'wudu' } },
    ]);

    const repo = new PrismaThirdPartyPlaceRepository(prisma);
    const place = await repo.findById('p1');

    expect(place).not.toBeNull();
    expect(place!.nameFr).toBe('Mosquée Al-Fath');
    expect(place!.tags).toEqual(['women_confirmed', 'wudu']);
    expect(place!.isFree).toBe(true);
    expect(place!.price).toBeNull();
  });

  it('maps a non-free place with a price', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([{ ...PLACE_ROW, is_free: false, price_amount: '20.00', price_currency: 'DZD' }]);

    const repo = new PrismaThirdPartyPlaceRepository(prisma);
    const place = await repo.findById('p1');

    expect(place!.price?.toDecimalString()).toBe('20.00');
  });
});
