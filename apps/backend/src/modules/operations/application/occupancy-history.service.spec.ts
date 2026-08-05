import { StationQueryService } from '../../station-network/application/station-query.service';
import { TelemetryReadingRepository } from '../domain/ports/telemetry-reading.repository';
import { OccupancyHistoryService } from './occupancy-history.service';

function createTelemetryRepoMock(): jest.Mocked<TelemetryReadingRepository> {
  return { findLatestValue: jest.fn(), findSeries: jest.fn() };
}

describe('OccupancyHistoryService', () => {
  it('returns a station-scoped occupancy series', async () => {
    const stationQueryService = { getById: jest.fn().mockResolvedValue({}) } as unknown as jest.Mocked<StationQueryService>;
    const telemetryReadingRepository = createTelemetryRepoMock();
    const from = new Date('2026-08-01T00:00:00Z');
    const to = new Date('2026-08-02T00:00:00Z');
    telemetryReadingRepository.findSeries.mockResolvedValue([
      { recordedAt: new Date('2026-08-01T06:00:00Z'), value: 3 },
      { recordedAt: new Date('2026-08-01T18:00:00Z'), value: 5 },
    ]);

    const service = new OccupancyHistoryService(stationQueryService, telemetryReadingRepository);
    const history = await service.getHistory('s1', from, to);

    expect(history).toEqual({
      stationId: 's1',
      points: [
        { timestamp: new Date('2026-08-01T06:00:00Z'), occupiedCabinCount: 3 },
        { timestamp: new Date('2026-08-01T18:00:00Z'), occupiedCabinCount: 5 },
      ],
    });
    expect(telemetryReadingRepository.findSeries).toHaveBeenCalledWith('s1', 'occupancy', from, to);
  });

  it('propagates a missing-station failure from StationQueryService (no local existence check)', async () => {
    const stationQueryService = {
      getById: jest.fn().mockRejectedValue(new Error('not found')),
    } as unknown as jest.Mocked<StationQueryService>;
    const telemetryReadingRepository = createTelemetryRepoMock();
    const service = new OccupancyHistoryService(stationQueryService, telemetryReadingRepository);

    await expect(service.getHistory('missing', new Date(), new Date())).rejects.toThrow('not found');
    expect(telemetryReadingRepository.findSeries).not.toHaveBeenCalled();
  });
});
