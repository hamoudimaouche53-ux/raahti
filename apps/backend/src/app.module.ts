import { Module } from '@nestjs/common';
import { PlatformModule } from './platform/platform.module';
import { IdentityModule } from './modules/identity/identity.module';

@Module({
  imports: [PlatformModule, IdentityModule],
})
export class AppModule {}
