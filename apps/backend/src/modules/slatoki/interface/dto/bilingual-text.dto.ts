import { ApiProperty } from '@nestjs/swagger';

/** Matches openapi.yaml components.schemas.BilingualText. Duplicated per-module — see station-network's copy for the rationale (ADR-0029-style independence, extended to Slatoki). */
export class BilingualTextDto {
  @ApiProperty()
  fr!: string;

  @ApiProperty()
  ar!: string;

  @ApiProperty()
  en!: string;
}
