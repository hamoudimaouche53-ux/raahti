import { ApiProperty } from '@nestjs/swagger';
import { SlatokiTent } from '../../domain/entities/slatoki-tent.entity';

/** Matches openapi.yaml components.schemas.SlatokiTent exactly. */
export class SlatokiTentDto {
  @ApiProperty({ enum: ['deployed', 'folded'] })
  deploymentStatus!: string;

  @ApiProperty()
  matCapacity!: number;

  @ApiProperty()
  hasLighting!: boolean;

  @ApiProperty()
  hasPrivacyCurtain!: boolean;

  static fromDomain(tent: SlatokiTent): SlatokiTentDto {
    const dto = new SlatokiTentDto();
    dto.deploymentStatus = tent.deploymentStatus;
    dto.matCapacity = tent.matCapacity;
    dto.hasLighting = tent.hasLighting;
    dto.hasPrivacyCurtain = tent.hasPrivacyCurtain;
    return dto;
  }
}
