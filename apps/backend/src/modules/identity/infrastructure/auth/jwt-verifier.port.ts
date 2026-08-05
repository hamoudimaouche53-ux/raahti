import { JwtClaims } from './jwt-claims';

export const JWT_VERIFIER = Symbol('JWT_VERIFIER');

export class JwtVerificationFailedException extends Error {
  constructor(reason: string) {
    super(`JWT verification failed: ${reason}`);
  }
}

/** Anti-corruption boundary around Supabase Auth's token verification (ADR-0009). */
export interface JwtVerifier {
  verify(token: string): Promise<JwtClaims>;
}
