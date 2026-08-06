import { ApiProperty } from '@nestjs/swagger';

/** Matches openapi.yaml components.schemas.BilingualText. Duplicated again here (also in composition/places and each Facilities module's own interface/dto) — see ADR-0029 (no sanctioned shared-interface-DTO location; the composition layer must not depend on either module's interface layer either). */
export class BilingualTextDto {
  @ApiProperty()
  fr!: string;

  @ApiProperty()
  ar!: string;

  @ApiProperty()
  en!: string;
}
