import { Inject, Injectable } from '@nestjs/common';
import { Money } from '../../../shared-kernel';
import { StationQueryService } from '../../station-network/application/station-query.service';
import { ACCESS_SESSION_REPOSITORY, AccessSessionRepository } from '../domain/ports/access-session.repository';

export interface VisitHistoryItem {
  id: string;
  placeName: string;
  occurredAt: Date;
  amount: Money | null;
}

export interface VisitHistoryResultPage {
  data: VisitHistoryItem[];
  nextCursor: string | null;
}

/**
 * GET /users/me/visit-history (EPIC-05 US-05.2). Resolves each row's
 * `placeName` via StationQueryService's batched cabinId -> station.code
 * lookup (the sanctioned exported surface — never StationRepository
 * directly, module-dependency-diagram.md §5 rule 1), avoiding N+1 across a
 * page of results.
 */
@Injectable()
export class VisitHistoryQueryService {
  constructor(
    @Inject(ACCESS_SESSION_REPOSITORY) private readonly accessSessionRepository: AccessSessionRepository,
    private readonly stationQueryService: StationQueryService,
  ) {}

  async listForUser(userId: string, cursor: string | null, limit: number): Promise<VisitHistoryResultPage> {
    const page = await this.accessSessionRepository.listVisitHistoryForUser(userId, cursor, limit);
    const codesByCabin = await this.stationQueryService.getStationCodesForCabinIds(page.data.map((row) => row.cabinId));

    return {
      data: page.data.map((row) => ({
        id: row.id,
        // Station has no bilingual name field (only `code`) — same treatment
        // StationQueryService.toPlaceSearchItem gives Station elsewhere
        // (documented judgment call there). Falling back to the raw cabinId
        // is a pathological case (a station-code lookup miss) that should
        // not happen in practice given the FK from cabin -> station.
        placeName: codesByCabin.get(row.cabinId) ?? row.cabinId,
        occurredAt: row.closedAt,
        amount: row.amount,
      })),
      nextCursor: page.nextCursor,
    };
  }
}
