/**
 * Opaque keyset-pagination cursor for StationReviewRepository.listByUserId
 * (GET /users/me/reviews, EPIC-05 US-05.2) — same technique as this module's
 * own `search-cursor.ts` (encode/decode a base64url JSON tiebreak pair), just
 * keyed on (createdAt, id) instead of (distanceMeters, id) since "my reviews"
 * is sorted newest-first rather than by distance.
 */
export interface ReviewCursor {
  createdAt: string;
  id: string;
}

export function encodeReviewCursor(cursor: ReviewCursor): string {
  return Buffer.from(JSON.stringify(cursor), 'utf8').toString('base64url');
}

export function decodeReviewCursor(value: string): ReviewCursor | null {
  try {
    const parsed: unknown = JSON.parse(Buffer.from(value, 'base64url').toString('utf8'));
    if (
      typeof parsed === 'object' &&
      parsed !== null &&
      typeof (parsed as ReviewCursor).createdAt === 'string' &&
      typeof (parsed as ReviewCursor).id === 'string'
    ) {
      return parsed as ReviewCursor;
    }
    return null;
  } catch {
    return null;
  }
}
