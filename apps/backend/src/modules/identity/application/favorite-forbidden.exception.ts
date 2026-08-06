import { DomainException } from '../../../shared-kernel';

/** Thrown when the authenticated caller is not the owner of the favorite they're acting on. */
export class FavoriteForbiddenException extends DomainException {
  readonly code = 'IDENTITY_FAVORITE_FORBIDDEN';
  readonly status = 403;

  constructor(favoriteId: string) {
    super(`Caller is not permitted to act on favorite ${favoriteId}.`);
  }
}
