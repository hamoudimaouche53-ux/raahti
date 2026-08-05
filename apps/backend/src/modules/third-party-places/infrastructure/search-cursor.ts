/** Opaque keyset-pagination cursor — see station-network's copy for the full rationale (duplicated per ADR-0029 independence). */
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
