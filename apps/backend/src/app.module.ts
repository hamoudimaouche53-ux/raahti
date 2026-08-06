import { Module } from '@nestjs/common';
import { PlatformModule } from './platform/platform.module';
import { IdentityModule } from './modules/identity/identity.module';
import { StationNetworkModule } from './modules/station-network/station-network.module';
import { ThirdPartyPlacesModule } from './modules/third-party-places/third-party-places.module';
import { PlacesModule } from './composition/places/places.module';
import { SlatokiModule } from './modules/slatoki/slatoki.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { OperationsModule } from './modules/operations/operations.module';
import { AccessPaymentModule } from './modules/access-payment/access-payment.module';
import { EmergencyModule } from './modules/emergency/emergency.module';

@Module({
  imports: [
    PlatformModule,
    IdentityModule,
    StationNetworkModule,
    ThirdPartyPlacesModule,
    PlacesModule,
    SlatokiModule,
    NotificationsModule,
    OperationsModule,
    AccessPaymentModule,
    EmergencyModule,
  ],
})
export class AppModule {}
