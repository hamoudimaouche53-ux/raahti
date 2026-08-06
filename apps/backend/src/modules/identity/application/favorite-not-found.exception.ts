import { DomainException } from '../../../shared-kernel';

export class FavoriteNotFoundException extends DomainException {
  readonly code = 'IDENTITY_FAVORITE_NOT_FOUND';
  readonly status = 404;

  constructor(id: string) {
    super(`Favorite ${id} was not found.`);
  }
}
