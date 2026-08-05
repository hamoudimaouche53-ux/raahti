import { StationQueryService } from '../../station-network/application/station-query.service';
import { AlertRepository } from '../domain/ports/alert.repository';
import { TelemetryReadingRepository } from '../domain/ports/telemetry-reading.repository';
import { FleetStatusService } from './fleet-status.service';

function createAlertRepoMock(): jest.Mocked<AlertRepository> {
  return { save: jest.fn(), findById: jest.fn(), findAll: jest.fn(), countActiveGroupedByStation: jest.fn() };
}

function createTelemetryRepoMock(): jest.Mocked<TelemetryReadingRepository> {
  return { findLatestValue: jest.fn(), findSeries: jest.fn() };
}

describe('FleetStatusService', () => {
  it('combines station/cabin data, active alert counts, and latest telemetry', async () => {
    const stationQueryService = {
      listAllForFleetView: jest.fn().mockResolvedValue([
        { stationId: 's1', status: 'active', cabins: [{ id: 'c1', code: 'C-01', type: 'H', occupancyStatus: 'free', isPaid: false, price: null }] },
        { stationId: 's2', status: 'maintenance', cabins: [] },
      ]),
    } as unknown as jest.Mocked<StationQueryService>;
    const alertRepository = createAlertRepoMock();
    alertRepository.countActiveGroupedByStation.mockResolvedValue(new Map([['s1', 2]]));
    const telemetryReadingRepository = createTelemetryRepoMock();
    telemetryReadingRepository.findLatestValue.mockImplementation(async (stationId, metric) => {
      if (stationId === 's1' && metric === 'battery_level') return 87;
      if (stationId === 's1' && metric === 'water_level') return 60;
      return null;
    });

    const service = new FleetStatusService(stationQueryService, alertRepository, telemetryReadingRepository);
    const fleet = await service.getFleetStatus();

    expect(fleet).toEqual([
      {
        stationId: 's1',
        batteryLevel: 87,
        waterLevel: 60,
        cabins: [{ id: 'c1', code: 'C-01', type: 'H', occupancyStatus: 'free', isPaid: false, price: null }],
        activeAlertCount: 2,
      },
      {
        stationId: 's2',
        batteryLevel: null,
        waterLevel: null,
        cabins: [],
        activeAlertCount: 0,
      },
    ]);
  });
});
