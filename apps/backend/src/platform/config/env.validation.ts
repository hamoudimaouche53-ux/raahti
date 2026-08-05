import { plainToInstance } from 'class-transformer';
import { IsIn, IsNotEmpty, IsOptional, IsPort, IsString, validateSync } from 'class-validator';

class EnvironmentVariables {
  @IsIn(['development', 'test', 'production'])
  @IsOptional()
  NODE_ENV?: string;

  @IsPort()
  @IsOptional()
  PORT?: string;

  @IsString()
  @IsNotEmpty()
  DATABASE_URL!: string;

  @IsString()
  @IsOptional()
  SUPABASE_URL?: string;

  @IsString()
  @IsOptional()
  SUPABASE_JWT_JWKS_URL?: string;

  @IsString()
  @IsOptional()
  SUPABASE_JWT_SECRET?: string;
}

/**
 * Fails fast at boot if required config is missing/malformed, and enforces the
 * "exactly one JWT verification strategy" rule from .env.example / Security
 * Architecture §1 rather than discovering it at first request.
 */
export function validateEnv(config: Record<string, unknown>): EnvironmentVariables {
  const validated = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });
  const errors = validateSync(validated, { skipMissingProperties: false });
  if (errors.length > 0) {
    throw new Error(`Invalid environment configuration: ${errors.toString()}`);
  }
  if (!validated.SUPABASE_JWT_JWKS_URL && !validated.SUPABASE_JWT_SECRET) {
    throw new Error(
      'Invalid environment configuration: one of SUPABASE_JWT_JWKS_URL or SUPABASE_JWT_SECRET is required.',
    );
  }
  return validated;
}
