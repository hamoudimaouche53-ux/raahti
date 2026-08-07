import { DomainException } from '../../../shared-kernel';

/**
 * The route provider (OSRM) could not be reached, or returned something other than a routable
 * response — distinct from [RouteNotFoundException]'s "reached it, no route exists" outcome.
 * Backs GET /routes/walking's 502.
 *
 * Deliberately takes no message parameter: `HttpExceptionFilter` forwards `DomainException.message`
 * verbatim to the client as `ProblemDetail.detail` for every `DomainException`, so this type's
 * message must never carry provider/network internals (host, DNS/connection error text, etc.).
 * Callers (`OsrmRouteProvider`) log that detail server-side via `Logger` before throwing this.
 */
export class RouteProviderUnavailableException extends DomainException {
  readonly code = 'ROUTE_PROVIDER_UNAVAILABLE';
  readonly status = 502;

  constructor() {
    super('The routing provider is temporarily unavailable. Please try again later.');
  }
}
