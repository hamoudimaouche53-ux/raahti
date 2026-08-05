import { Global, MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TerminusModule } from '@nestjs/terminus';
import configuration from './config/configuration';
import { validateEnv } from './config/env.validation';
import { PrismaService } from './database/prisma.service';
import { HealthController } from './health/health.controller';
import { CorrelationIdMiddleware } from './http/correlation-id.middleware';

/**
 * Cross-cutting infrastructure shared by every module (platform README): config,
 * structured logging, health checks, correlation-id middleware. @Global so
 * PrismaService/ConfigService don't need re-importing in every feature module.
 */
@Global()
@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
      validate: validateEnv,
    }),
    TerminusModule,
  ],
  controllers: [HealthController],
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PlatformModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(CorrelationIdMiddleware).forRoutes('*');
  }
}
