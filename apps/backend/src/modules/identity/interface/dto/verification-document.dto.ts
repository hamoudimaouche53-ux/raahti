import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsNotEmpty, IsString } from 'class-validator';
import { VerificationDocument } from '../../domain/entities/verification-document.entity';

/** Matches openapi.yaml components.schemas.VerificationDocumentCreateRequest exactly (FR-USR-03). */
export class VerificationDocumentCreateRequestDto {
  @ApiProperty({ enum: ['diabetic_certificate'] })
  @IsIn(['diabetic_certificate'])
  documentType!: string;

  @ApiProperty({ description: 'Object-storage pointer, provider-agnostic.' })
  @IsString()
  @IsNotEmpty()
  storageRef!: string;
}

/** Matches openapi.yaml components.schemas.VerificationDocument exactly. */
export class VerificationDocumentResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty()
  documentType!: string;

  @ApiProperty({ enum: ['pending', 'approved', 'rejected'] })
  reviewStatus!: string;

  @ApiProperty({ format: 'date-time' })
  submittedAt!: string;

  static fromDomain(document: VerificationDocument): VerificationDocumentResponseDto {
    const dto = new VerificationDocumentResponseDto();
    dto.id = document.id;
    dto.documentType = document.documentType;
    dto.reviewStatus = document.reviewStatus;
    dto.submittedAt = document.submittedAt.toISOString();
    return dto;
  }
}
