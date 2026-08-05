import { Body, Controller, Get, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { PaymentMethodService } from '../../application/payment-method.service';
import { JwtClaims } from '../../infrastructure/auth/jwt-claims';
import { CurrentUser } from '../decorators/current-user.decorator';
import { PaymentMethodCreateRequestDto, PaymentMethodResponseDto } from '../dto/payment-method.dto';

/** GET/POST /users/me/payment-methods — openapi.yaml tag Identity. */
@ApiTags('Identity')
@ApiBearerAuth('bearerAuth')
@Controller('users/me/payment-methods')
export class PaymentMethodsController {
  constructor(private readonly paymentMethodService: PaymentMethodService) {}

  @Get()
  async list(@CurrentUser() claims: JwtClaims): Promise<{ data: PaymentMethodResponseDto[] }> {
    const methods = await this.paymentMethodService.list(claims.sub);
    return { data: methods.map((method) => PaymentMethodResponseDto.fromDomain(method)) };
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @CurrentUser() claims: JwtClaims,
    @Body() body: PaymentMethodCreateRequestDto,
  ): Promise<PaymentMethodResponseDto> {
    const method = await this.paymentMethodService.create(claims.sub, body);
    return PaymentMethodResponseDto.fromDomain(method);
  }
}
