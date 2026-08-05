import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { VerificationDocumentService } from '../../application/verification-document.service';
import { JwtClaims } from '../../infrastructure/auth/jwt-claims';
import { CurrentUser } from '../decorators/current-user.decorator';
import { VerificationDocumentCreateRequestDto, VerificationDocumentResponseDto } from '../dto/verification-document.dto';

/** POST /users/me/verification-documents — openapi.yaml tag Identity (FR-USR-03). */
@ApiTags('Identity')
@ApiBearerAuth('bearerAuth')
@Controller('users/me/verification-documents')
export class VerificationDocumentsController {
  constructor(private readonly verificationDocumentService: VerificationDocumentService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async submit(
    @CurrentUser() claims: JwtClaims,
    @Body() body: VerificationDocumentCreateRequestDto,
  ): Promise<VerificationDocumentResponseDto> {
    const document = await this.verificationDocumentService.submit(claims.sub, body);
    return VerificationDocumentResponseDto.fromDomain(document);
  }
}
