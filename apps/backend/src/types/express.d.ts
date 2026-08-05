import { AuthenticatedPrincipal } from '../platform/auth';

declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedPrincipal;
    }
  }
}
