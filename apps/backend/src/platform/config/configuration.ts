export interface AppConfig {
  nodeEnv: string;
  port: number;
  databaseUrl: string;
  supabaseUrl: string;
  supabaseJwtJwksUrl?: string;
  supabaseJwtSecret?: string;
  corsAllowedOrigins: string[];
  osrmBaseUrl: string;
}

/** Public OSRM demo instance — no SLA/rate-limit guarantee, fine for local
 * development; production deployments should set OSRM_BASE_URL to a
 * self-hosted instance (RoutingModule's OsrmRouteProvider README). */
const DEFAULT_OSRM_BASE_URL = 'https://router.project-osrm.org';

export default (): { app: AppConfig } => ({
  app: {
    nodeEnv: process.env.NODE_ENV ?? 'development',
    port: Number(process.env.PORT ?? 3000),
    databaseUrl: process.env.DATABASE_URL ?? '',
    supabaseUrl: process.env.SUPABASE_URL ?? '',
    supabaseJwtJwksUrl: process.env.SUPABASE_JWT_JWKS_URL || undefined,
    supabaseJwtSecret: process.env.SUPABASE_JWT_SECRET || undefined,
    corsAllowedOrigins: (process.env.CORS_ALLOWED_ORIGINS ?? '')
      .split(',')
      .map((origin) => origin.trim())
      .filter(Boolean),
    osrmBaseUrl: process.env.OSRM_BASE_URL || DEFAULT_OSRM_BASE_URL,
  },
});
