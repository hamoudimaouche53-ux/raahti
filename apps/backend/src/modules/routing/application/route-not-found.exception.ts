import { DomainException } from '../../../shared-kernel';

/** The route provider reached a definitive "no route exists" answer (e.g. origin/destination not connected by any walkable way) — backs GET /routes/walking's 404. */
export class RouteNotFoundException extends DomainException {
  readonly code = 'ROUTE_NOT_FOUND';
  readonly status = 404;

  constructor() {
    super('No walking route was found between the given points.');
  }
}
