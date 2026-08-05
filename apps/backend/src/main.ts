import 'reflect-metadata';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { AppConfig } from './platform/config/configuration';
import { HttpExceptionFilter } from './platform/http/http-exception.filter';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  const config = app.get(ConfigService).get<AppConfig>('app')!;

  app.use(helmet());
  app.enableCors({ origin: config.corsAllowedOrigins, credentials: true });

  // URL-path versioning (api-architecture.md §2) — this container serves /v1.
  app.setGlobalPrefix('v1', { exclude: ['health'] });

  // No unvalidated input ever reaches the Application layer (security-architecture.md §5).
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  app.useGlobalFilters(new HttpExceptionFilter());

  const swaggerConfig = new DocumentBuilder()
    .setTitle('RAHATI Platform API')
    .setDescription('Generated from NestJS decorators — checked against docs/api/openapi.yaml in CI (api-architecture.md §1).')
    .setVersion('1.0.0')
    .addBearerAuth({ type: 'http', scheme: 'bearer', bearerFormat: 'JWT' }, 'bearerAuth')
    .build();
  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('docs', app, document);

  await app.listen(config.port);
}

void bootstrap();
