import { Module } from '@nestjs/common';
import { PlatformModule } from './platform/platform.module';
import { IdentityModule } from './modules/identity/identity.module';
import { StationNetworkModule } from './modules/station-network/station-network.module';
import { ThirdPartyPlacesModule } from './modules/third-party-places/third-party-places.module';
import { PlacesModule } from './composition/places/places.module';

@Module({
  imports: [PlatformModule, IdentityModule, StationNetworkModule, ThirdPartyPlacesModule, PlacesModule],
})
export class AppModule {}
