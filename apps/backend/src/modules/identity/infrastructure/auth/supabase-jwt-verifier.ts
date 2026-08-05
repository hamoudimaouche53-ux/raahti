import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createRemoteJWKSet, jwtVerify, JWTVerifyGetKey } from 'jose';
import { AppConfig } from '../../../../platform/config/configuration';
import { JwtClaims } from './jwt-claims';
import { JwtVerificationFailedException, JwtVerifier } from './jwt-verifier.port';

/**
 * Verifies Supabase Auth-issued JWTs (Security Architecture §1). Supports either
 * documented strategy, selected by which env var is configured (.env.example):
 * remote JWKS (asymmetric, current Supabase default) or a shared HS256 secret
 * (legacy Supabase projects) — never both.
 */
@Injectable()
export class SupabaseJwtVerifier implements JwtVerifier {
  private readonly jwksGetKey?: JWTVerifyGetKey;
  private readonly hmacSecret?: Uint8Array;

  constructor(configService: ConfigService) {
    const config = configService.get<AppConfig>('app')!;
    if (config.supabaseJwtJwksUrl) {
      this.jwksGetKey = createRemoteJWKSet(new URL(config.supabaseJwtJwksUrl));
    } else if (config.supabaseJwtSecret) {
      this.hmacSecret = new TextEncoder().encode(config.supabaseJwtSecret);
    } else {
      // env.validation.ts already enforces one of the two is present at boot.
      throw new Error('No Supabase JWT verification strategy configured.');
    }
  }

  async verify(token: string): Promise<JwtClaims> {
    try {
      const { payload } = this.jwksGetKey
        ? await jwtVerify(token, this.jwksGetKey)
        : await jwtVerify(token, this.hmacSecret!);
      return payload as unknown as JwtClaims;
    } catch (error) {
      throw new JwtVerificationFailedException((error as Error).message);
    }
  }
}
