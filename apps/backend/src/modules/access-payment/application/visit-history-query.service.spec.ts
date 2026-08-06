import { Money } from '../../../shared-kernel';
import { StationQueryService } from '../../station-network/application/station-query.service';
import { AccessSessionRepository } from '../domain/ports/access-session.repository';
import { VisitHistoryQueryService } from './visit-history-query.service';

function createRepoMock(): jest.Mocked<AccessSessionRepository> {
  return {
    save: jest.fn(),
    findById: jest.fn(),
    findActiveByCabinId: jest.fn(),
    listVisitHistoryForUser: jest.fn(),
  };
}

function createStationQueryServiceMock(): jest.Mocked<Pick<StationQueryService, 'getStationCodesForCabinIds'>> {
  return { getStationCodesForCabinIds: jest.fn() };
}

describe('VisitHistoryQueryService', () => {
  it('resolves placeName from the batched station-code lookup and passes through amount/nextCursor', async () => {
    const repo = createRepoMock();
    const closedAt = new Date('2026-08-01T10:00:00Z');
    repo.listVisitHistoryForUser.mockResolvedValue({
      data: [{ id: 'as1', cabinId: 'c1', closedAt, amount: Money.fromDecimalString('50.00', 'DZD') }],
      nextCursor: 'cursor-1',
    });
    const stationQueryService = createStationQueryServiceMock();
    stationQueryService.getStationCodesForCabinIds.mockResolvedValue(new Map([['c1', 'ST-001']]));
    const service = new VisitHistoryQueryService(repo, stationQueryService as unknown as StationQueryService);

    const page = await service.listForUser('u1', null, 20);

    expect(repo.listVisitHistoryForUser).toHaveBeenCalledWith('u1', null, 20);
    expect(stationQueryService.getStationCodesForCabinIds).toHaveBeenCalledWith(['c1']);
    expect(page.data).toEqual([
      { id: 'as1', placeName: 'ST-001', occurredAt: closedAt, amount: expect.any(Money) },
    ]);
    expect(page.data[0].amount?.toDecimalString()).toBe('50.00');
    expect(page.nextCursor).toBe('cursor-1');
  });

  it('maps a free-cabin visit (no transaction) to a null amount', async () => {
    const repo = createRepoMock();
    const closedAt = new Date('2026-08-01T10:00:00Z');
    repo.listVisitHistoryForUser.mockResolvedValue({
      data: [{ id: 'as1', cabinId: 'c1', closedAt, amount: null }],
      nextCursor: null,
    });
    const stationQueryService = createStationQueryServiceMock();
    stationQueryService.getStationCodesForCabinIds.mockResolvedValue(new Map([['c1', 'ST-001']]));
    const service = new VisitHistoryQueryService(repo, stationQueryService as unknown as StationQueryService);

    const page = await service.listForUser('u1', null, 20);

    expect(page.data[0].amount).toBeNull();
  });

  it('falls back to the raw cabinId when the station-code lookup has no entry for it (pathological case)', async () => {
    const repo = createRepoMock();
    const closedAt = new Date('2026-08-01T10:00:00Z');
    repo.listVisitHistoryForUser.mockResolvedValue({
      data: [{ id: 'as1', cabinId: 'missing-cabin', closedAt, amount: null }],
      nextCursor: null,
    });
    const stationQueryService = createStationQueryServiceMock();
    stationQueryService.getStationCodesForCabinIds.mockResolvedValue(new Map());
    const service = new VisitHistoryQueryService(repo, stationQueryService as unknown as StationQueryService);

    const page = await service.listForUser('u1', null, 20);

    expect(page.data[0].placeName).toBe('missing-cabin');
  });

  it('passes an empty cabinId array through when there are no visit-history rows', async () => {
    const repo = createRepoMock();
    repo.listVisitHistoryForUser.mockResolvedValue({ data: [], nextCursor: null });
    const stationQueryService = createStationQueryServiceMock();
    stationQueryService.getStationCodesForCabinIds.mockResolvedValue(new Map());
    const service = new VisitHistoryQueryService(repo, stationQueryService as unknown as StationQueryService);

    const page = await service.listForUser('u1', null, 20);

    expect(stationQueryService.getStationCodesForCabinIds).toHaveBeenCalledWith([]);
    expect(page.data).toEqual([]);
  });
});
