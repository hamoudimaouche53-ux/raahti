/**
 * Opaque keyset-pagination cursor for `listVisitHistoryForUser`
 * (api-architecture.md §6), same base64-of-JSON technique as
 * station-network's `search-cursor.ts` (that module's own `SearchCursor` is
 * infrastructure/-private and this module may not import across that
 * boundary — module-dependency-diagram.md §5 rule 1 — so a small local copy
 * lives here instead, encoding the (closedAt, id) tiebreak this query's
 * `ORDER BY closed_at DESC, id DESC` needs to resume a descending keyset
 * scan).
 */
export interface VisitHistoryCursor {
  closedAt: string;
  id: string;
}

export function encodeVisitHistoryCursor(cursor: VisitHistoryCursor): string {
  return Buffer.from(JSON.stringify(cursor), 'utf8').toString('base64url');
}

export function decodeVisitHistoryCursor(value: string): VisitHistoryCursor | null {
  try {
    const parsed: unknown = JSON.parse(Buffer.from(value, 'base64url').toString('utf8'));
    if (
      typeof parsed === 'object' &&
      parsed !== null &&
      typeof (parsed as VisitHistoryCursor).closedAt === 'string' &&
      typeof (parsed as VisitHistoryCursor).id === 'string'
    ) {
      return parsed as VisitHistoryCursor;
    }
    return null;
  } catch {
    return null;
  }
}
