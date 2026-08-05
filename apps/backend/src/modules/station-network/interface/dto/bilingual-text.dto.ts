import { ApiProperty } from '@nestjs/swagger';

/**
 * Matches openapi.yaml components.schemas.BilingualText. Duplicated per-module
 * (also in third-party-places/interface/dto) rather than shared, per ADR-0029's
 * independence requirement — no sanctioned shared-interface-DTO location exists
 * (shared-kernel is Domain-layer-only, repository-structure.md §3).
 */
export class BilingualTextDto {
  @ApiProperty()
  fr!: string;

  @ApiProperty()
  ar!: string;

  @ApiProperty()
  en!: string;
}
