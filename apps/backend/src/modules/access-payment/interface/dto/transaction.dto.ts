import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AccessSession } from '../../domain/entities/access-session.entity';
import { Transaction } from '../../domain/entities/transaction.entity';
import { AccessSessionResponseDto } from './access-session.dto';
import { MoneyDto } from './money.dto';

const TRANSACTION_STATUSES = ['pending', 'authorized', 'captured', 'failed', 'refunded'] as const;

/**
 * Matches openapi.yaml components.schemas.Transaction. That schema declares
 * no `required` list at all, so `id`/`amount`/`discountApplied`/`status`
 * are legitimately optional here — used for the free-cabin payment response
 * (Domain Model §6: "a free-access session produces no transaction row"),
 * where `transaction` is `null` and only `accessSession` is populated. No
 * openapi.yaml change was needed for this case; a fabricated placeholder
 * Transaction would have been worse than honestly omitting the fields.
 */
export class TransactionResponseDto {
  @ApiPropertyOptional({ format: 'uuid' })
  id?: string;

  @ApiPropertyOptional({ type: MoneyDto })
  amount?: MoneyDto;

  @ApiPropertyOptional({ nullable: true })
  discountApplied?: string | null;

  @ApiPropertyOptional({ enum: TRANSACTION_STATUSES })
  status?: string;

  @ApiProperty({ type: AccessSessionResponseDto })
  accessSession!: AccessSessionResponseDto;

  static fromDomain(transaction: Transaction | null, session: AccessSession): TransactionResponseDto {
    const dto = new TransactionResponseDto();
    dto.accessSession = AccessSessionResponseDto.fromDomain(session);
    if (transaction) {
      dto.id = transaction.id;
      dto.amount = MoneyDto.fromDomain(transaction.amount);
      dto.discountApplied = transaction.discountApplied !== null ? String(transaction.discountApplied) : null;
      dto.status = transaction.status;
    }
    return dto;
  }
}
