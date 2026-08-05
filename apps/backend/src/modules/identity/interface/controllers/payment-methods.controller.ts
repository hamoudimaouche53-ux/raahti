import { Body, Controller, Get, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { PaymentMethodService } from '../../application/payment-method.service';
import { AuthenticatedPrincipal, CurrentUser } from '../../../../platform/auth';
import { PaymentMethodCreateRequestDto, PaymentMethodResponseDto } from '../dto/payment-method.dto';

/** GET/POST /users/me/payment-methods — openapi.yaml tag Identity. */
@ApiTags('Identity')
@ApiBearerAuth('bearerAuth')
@Controller('users/me/payment-methods')
export class PaymentMethodsController {
  constructor(private readonly paymentMethodService: PaymentMethodService) {}

  @Get()
  async list(@CurrentUser() principal: AuthenticatedPrincipal): Promise<{ data: PaymentMethodResponseDto[] }> {
    const methods = await this.paymentMethodService.list(principal.sub);
    return { data: methods.map((method) => PaymentMethodResponseDto.fromDomain(method)) };
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Body() body: PaymentMethodCreateRequestDto,
  ): Promise<PaymentMethodResponseDto> {
    const method = await this.paymentMethodService.create(principal.sub, body);
    return PaymentMethodResponseDto.fromDomain(method);
  }
}
