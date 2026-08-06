import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthenticatedPrincipal, CurrentUser } from '../../../../platform/auth';
import { RateLimit, RateLimitGuard } from '../../../../platform/http/rate-limit.guard';
import { AccessSessionQueryService } from '../../application/access-session-query.service';
import { AuthorizeAndCapturePaymentService } from '../../application/authorize-and-capture-payment.service';
import { CompleteAccessSessionService } from '../../application/complete-access-session.service';
import { InitiateAccessSessionService } from '../../application/initiate-access-session.service';
import { AccessSessionCreateRequestDto, AccessSessionResponseDto } from '../dto/access-session.dto';
import { PaymentRequestDto } from '../dto/payment-request.dto';
import { TransactionResponseDto } from '../dto/transaction.dto';

/**
 * POST/GET /access-sessions... — openapi.yaml tag AccessPayment
 * (FR-PAY-01..06). Every route sits behind the already-global JwtAuthGuard
 * (IdentityModule's APP_GUARD wiring) — no extra auth decorator needed, no
 * `@Roles()`/`@RequireMfa()` (any authenticated usager may use these
 * routes). Rate-limited only on the two payment-initiation-class writes
 * (api-architecture.md §9), not on GET or the manual-complete route.
 */
@ApiTags('AccessPayment')
@ApiBearerAuth('bearerAuth')
@Controller('access-sessions')
export class AccessSessionsController {
  constructor(
    private readonly initiateAccessSessionService: InitiateAccessSessionService,
    private readonly authorizeAndCapturePaymentService: AuthorizeAndCapturePaymentService,
    private readonly accessSessionQueryService: AccessSessionQueryService,
    private readonly completeAccessSessionService: CompleteAccessSessionService,
  ) {}

  @Post()
  @HttpCode(201)
  @UseGuards(RateLimitGuard)
  @RateLimit(10, 60_000)
  async create(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Body() body: AccessSessionCreateRequestDto,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
  ): Promise<AccessSessionResponseDto> {
    if (!idempotencyKey) {
      throw new BadRequestException('Idempotency-Key header is required.');
    }
    const session = await this.initiateAccessSessionService.execute({
      qrCodeScanned: body.qrCodeScanned,
      userId: principal.sub,
      idempotencyKey,
    });
    return AccessSessionResponseDto.fromDomain(session);
  }

  @Get(':sessionId')
  async getById(@Param('sessionId', ParseUUIDPipe) sessionId: string): Promise<AccessSessionResponseDto> {
    const session = await this.accessSessionQueryService.getById(sessionId);
    return AccessSessionResponseDto.fromDomain(session);
  }

  @Post(':sessionId/payments')
  @HttpCode(HttpStatus.OK)
  @UseGuards(RateLimitGuard)
  @RateLimit(10, 60_000)
  async pay(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Param('sessionId', ParseUUIDPipe) sessionId: string,
    @Body() body: PaymentRequestDto,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
  ): Promise<TransactionResponseDto> {
    if (!idempotencyKey) {
      throw new BadRequestException('Idempotency-Key header is required.');
    }
    const { session, transaction } = await this.authorizeAndCapturePaymentService.execute({
      accessSessionId: sessionId,
      callerId: principal.sub,
      paymentMethodId: body.paymentMethodId,
      applyEmergencyDiscount: body.applyEmergencyDiscount,
      idempotencyKey,
    });
    return TransactionResponseDto.fromDomain(transaction, session);
  }

  @Post(':sessionId/complete')
  @HttpCode(HttpStatus.OK)
  async complete(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Param('sessionId', ParseUUIDPipe) sessionId: string,
  ): Promise<AccessSessionResponseDto> {
    const session = await this.completeAccessSessionService.execute({
      accessSessionId: sessionId,
      callerId: principal.sub,
    });
    return AccessSessionResponseDto.fromDomain(session);
  }
}
