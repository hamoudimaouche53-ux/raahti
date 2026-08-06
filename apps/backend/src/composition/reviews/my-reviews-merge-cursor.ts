/**
 * Composite cursor for GET /users/me/reviews (mirrors composition/places's
 * places-merge-cursor.ts exactly — same "track each source module's own
 * opaque cursor independently" technique, adapted from distance-sort to
 * createdAt-desc-sort). `EXHAUSTED_MARKER` distinguishes "never queried"
 * (absent/null) from "queried and confirmed no more results" (avoids
 * re-querying an exhausted source on every subsequent page).
 */
export const EXHAUSTED_MARKER = '__end__';

export interface MergeCursor {
  station: string | null;
  thirdParty: string | null;
}

export function encodeMergeCursor(cursor: MergeCursor): string {
  return Buffer.from(JSON.stringify(cursor), 'utf8').toString('base64url');
}

export function decodeMergeCursor(value: string | null | undefined): MergeCursor {
  if (!value) {
    return { station: null, thirdParty: null };
  }
  try {
    const parsed: unknown = JSON.parse(Buffer.from(value, 'base64url').toString('utf8'));
    if (typeof parsed === 'object' && parsed !== null) {
      const candidate = parsed as Partial<MergeCursor>;
      return {
        station: typeof candidate.station === 'string' ? candidate.station : null,
        thirdParty: typeof candidate.thirdParty === 'string' ? candidate.thirdParty : null,
      };
    }
  } catch {
    // fall through to the start-from-beginning default below
  }
  return { station: null, thirdParty: null };
}

/**
 * Per-item resume cursor, in the SAME (base64 of JSON {createdAt, id}) shape
 * each source module's own repository uses internally (see each module's
 * infrastructure/review-cursor.ts) — duplicated here (not imported) because
 * the composition layer may not depend on either module's infrastructure/
 * layer (ADR-0029, module-dependency-diagram.md §5 rule 1). All three copies
 * must stay in lockstep if this shape ever changes.
 */
export function encodeItemCursor(item: { createdAt: Date; id: string }): string {
  return Buffer.from(JSON.stringify({ createdAt: item.createdAt.toISOString(), id: item.id }), 'utf8').toString(
    'base64url',
  );
}
