import { GeoPosition } from '../../../shared-kernel';
import { UserQueryService } from '../../identity/application/user-query.service';
import { NearestAccessibleFacility, StationQueryService } from '../../station-network/application/station-query.service';
import { EmergencyQueryService } from './emergency-query.service';

const POSITION = GeoPosition.of(36.75, 3.05);

/** Duck-typed — the real `User` domain entity lives in identity/domain, which
 * emergency/application may not import (module-dependency-diagram.md §3: only
 * IdentityModule's exported *QueryService is a sanctioned dependency). */
type FakeUser = { diabeticVerificationStatus: 'none' | 'pending' | 'verified' | 'rejected' };

function aFacility(overrides: Partial<NearestAccessibleFacility> = {}): NearestAccessibleFacility {
  return {
    place: {
      id: 's1',
      placeKind: 'station',
      name: { fr: 'ST-001', ar: 'ST-001', en: 'ST-001' },
      position: { lat: 36.75, lng: 3.05 },
      pinColor: 'blue',
      distanceMeters: 500,
      averageRating: null,
      reviewCount: 0,
      isFree: false,
      tags: [],
      hasSlatokiTent: false,
    },
    nearestCabinId: 'c1',
    ...overrides,
  };
}

function aUser(diabeticVerificationStatus: FakeUser['diabeticVerificationStatus'] = 'verified'): FakeUser {
  return { diabeticVerificationStatus };
}

function createServices(user: FakeUser | null, facility: NearestAccessibleFacility | null) {
  const userQueryService = { findById: jest.fn().mockResolvedValue(user) } as unknown as jest.Mocked<UserQueryService>;
  const stationQueryService = {
    findNearestAccessible: jest.fn().mockResolvedValue(facility),
  } as unknown as jest.Mocked<StationQueryService>;
  return { userQueryService, stationQueryService };
}

describe('EmergencyQueryService', () => {
  it('returns discountEligible: true for a verified user', async () => {
    const { userQueryService, stationQueryService } = createServices(aUser('verified'), aFacility());
    const service = new EmergencyQueryService(userQueryService, stationQueryService);

    const result = await service.findNearestFacility({ userId: 'u1', position: POSITION });

    expect(result?.discountEligible).toBe(true);
  });

  it.each(['none', 'pending', 'rejected'] as const)('returns discountEligible: false for an unverified user (%s)', async (status) => {
    const { userQueryService, stationQueryService } = createServices(aUser(status), aFacility());
    const service = new EmergencyQueryService(userQueryService, stationQueryService);

    const result = await service.findNearestFacility({ userId: 'u1', position: POSITION });

    expect(result?.discountEligible).toBe(false);
  });

  it('returns null when no accessible facility is found, regardless of user', async () => {
    const { userQueryService, stationQueryService } = createServices(aUser('verified'), null);
    const service = new EmergencyQueryService(userQueryService, stationQueryService);

    const result = await service.findNearestFacility({ userId: 'u1', position: POSITION });

    expect(result).toBeNull();
  });

  it('returns discountEligible: false (not thrown) when the user lookup returns null', async () => {
    const { userQueryService, stationQueryService } = createServices(null, aFacility());
    const service = new EmergencyQueryService(userQueryService, stationQueryService);

    const result = await service.findNearestFacility({ userId: 'unknown', position: POSITION });

    expect(result?.discountEligible).toBe(false);
    expect(result?.place.id).toBe('s1');
  });

  it('passes place and nearestCabinId through unchanged', async () => {
    const facility = aFacility({ nearestCabinId: null });
    const { userQueryService, stationQueryService } = createServices(aUser('verified'), facility);
    const service = new EmergencyQueryService(userQueryService, stationQueryService);

    const result = await service.findNearestFacility({ userId: 'u1', position: POSITION });

    expect(result?.nearestCabinId).toBeNull();
    expect(result?.place).toEqual(facility.place);
  });
});
