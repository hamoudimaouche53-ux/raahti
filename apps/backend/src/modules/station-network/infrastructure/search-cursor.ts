/**
 * Opaque keyset-pagination cursor (api-architecture.md §6 — cursor-based
 * pagination chosen specifically because nearby-place results are
 * spatially-ordered and frequently-changing; offset pagination would skip/
 * duplicate rows as occupancy changes between pages). Encodes the
 * (distance, id) tiebreak needed to resume a distance-sorted keyset scan.
 */
export interface SearchCursor {
  distanceMeters: number;
  id: string;
}

export function encodeSearchCursor(cursor: SearchCursor): string {
  return Buffer.from(JSON.stringify(cursor), 'utf8').toString('base64url');
}

export function decodeSearchCursor(value: string): SearchCursor | null {
  try {
    const parsed: unknown = JSON.parse(Buffer.from(value, 'base64url').toString('utf8'));
    if (
      typeof parsed === 'object' &&
      parsed !== null &&
      typeof (parsed as SearchCursor).distanceMeters === 'number' &&
      typeof (parsed as SearchCursor).id === 'string'
    ) {
      return parsed as SearchCursor;
    }
    return null;
  } catch {
    return null;
  }
}
