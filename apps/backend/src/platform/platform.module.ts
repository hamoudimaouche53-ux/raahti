import { Global, MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TerminusModule } from '@nestjs/terminus';
import { DOMAIN_EVENT_BUS } from '../shared-kernel';
import configuration from './config/configuration';
import { validateEnv } from './config/env.validation';
import { PrismaService } from './database/prisma.service';
import { InProcessEventBus } from './events/in-process-event-bus';
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
  providers: [PrismaService, { provide: DOMAIN_EVENT_BUS, useClass: InProcessEventBus }],
  exports: [PrismaService, DOMAIN_EVENT_BUS],
})
export class PlatformModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(CorrelationIdMiddleware).forRoutes('*');
  }
}
