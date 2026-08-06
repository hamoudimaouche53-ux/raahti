import { Favorite, InvalidFavoriteTargetException } from './favorite.entity';

describe('Favorite', () => {
  it('accepts a station-only target', () => {
    const fav = Favorite.create({ id: 'f1', userId: 'u1', stationId: 's1' });
    expect(fav.stationId).toBe('s1');
    expect(fav.thirdPartyPlaceId).toBeNull();
  });

  it('accepts a third-party-place-only target', () => {
    const fav = Favorite.create({ id: 'f1', userId: 'u1', thirdPartyPlaceId: 'p1' });
    expect(fav.thirdPartyPlaceId).toBe('p1');
  });

  it('rejects neither target set', () => {
    expect(() => Favorite.create({ id: 'f1', userId: 'u1' })).toThrow(InvalidFavoriteTargetException);
  });

  it('rejects both targets set', () => {
    expect(() => Favorite.create({ id: 'f1', userId: 'u1', stationId: 's1', thirdPartyPlaceId: 'p1' })).toThrow(
      InvalidFavoriteTargetException,
    );
  });

  it('defaults notifyOnAvailable to false', () => {
    const fav = Favorite.create({ id: 'f1', userId: 'u1', stationId: 's1' });
    expect(fav.notifyOnAvailable).toBe(false);
  });

  it('setNotifyOnAvailable flips the flag in place', () => {
    const fav = Favorite.create({ id: 'f1', userId: 'u1', stationId: 's1' });

    fav.setNotifyOnAvailable(true);
    expect(fav.notifyOnAvailable).toBe(true);

    fav.setNotifyOnAvailable(false);
    expect(fav.notifyOnAvailable).toBe(false);
  });

  it('setNotifyOnAvailable does not affect other properties', () => {
    const fav = Favorite.create({ id: 'f1', userId: 'u1', stationId: 's1' });

    fav.setNotifyOnAvailable(true);

    expect(fav.id).toBe('f1');
    expect(fav.userId).toBe('u1');
    expect(fav.stationId).toBe('s1');
    expect(fav.thirdPartyPlaceId).toBeNull();
  });
});
