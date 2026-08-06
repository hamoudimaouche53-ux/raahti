import { Cabin } from '../domain/entities/cabin.entity';
import { StationRepository } from '../domain/ports/station.repository';
import { CabinNotFoundException } from './cabin-not-found.exception';
import { CabinUnavailableException } from './cabin-unavailable.exception';
import { StationCommandService } from './station-command.service';

function freeCabin(overrides: Partial<Parameters<typeof Cabin.restore>[0]> = {}) {
  return Cabin.restore({
    id: 'c1',
    stationId: 's1',
    code: 'C-01',
    type: 'H',
    occupancyStatus: 'free',
    isPaid: false,
    price: null,
    ...overrides,
  });
}

describe('StationCommandService', () => {
  let stationRepository: jest.Mocked<StationRepository>;
  let service: StationCommandService;

  beforeEach(() => {
    stationRepository = {
      findById: jest.fn(),
      findAll: jest.fn(),
      searchNearby: jest.fn(),
      findCabinById: jest.fn(),
      updateCabinOccupancy: jest.fn(),
      findNearestAccessible: jest.fn(),
    };
    service = new StationCommandService(stationRepository);
  });

  describe('checkCabinAvailability', () => {
    it('returns the cabin when it exists and is free', async () => {
      const cabin = freeCabin();
      stationRepository.findCabinById.mockResolvedValue(cabin);

      const result = await service.checkCabinAvailability('c1');

      expect(result).toBe(cabin);
    });

    it('throws CabinNotFoundException when the cabin does not exist', async () => {
      stationRepository.findCabinById.mockResolvedValue(null);

      await expect(service.checkCabinAvailability('missing')).rejects.toThrow(CabinNotFoundException);
    });

    it('throws CabinUnavailableException when the cabin is occupied', async () => {
      stationRepository.findCabinById.mockResolvedValue(freeCabin({ occupancyStatus: 'occupied' }));

      await expect(service.checkCabinAvailability('c1')).rejects.toThrow(CabinUnavailableException);
    });

    it('throws CabinUnavailableException when the cabin is out_of_service', async () => {
      stationRepository.findCabinById.mockResolvedValue(freeCabin({ occupancyStatus: 'out_of_service' }));

      await expect(service.checkCabinAvailability('c1')).rejects.toThrow(CabinUnavailableException);
    });
  });

  describe('setCabinOccupancy', () => {
    it('delegates to the repository', async () => {
      await service.setCabinOccupancy('c1', 'occupied');
      expect(stationRepository.updateCabinOccupancy).toHaveBeenCalledWith('c1', 'occupied');
    });
  });
});
