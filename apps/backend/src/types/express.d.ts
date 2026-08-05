import { JwtClaims } from '../modules/identity/infrastructure/auth/jwt-claims';

declare global {
  namespace Express {
    interface Request {
      user?: JwtClaims;
    }
  }
}
