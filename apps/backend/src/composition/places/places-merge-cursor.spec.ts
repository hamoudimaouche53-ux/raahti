import { decodeMergeCursor, encodeItemCursor, encodeMergeCursor, EXHAUSTED_MARKER } from './places-merge-cursor';

describe('places merge cursor', () => {
  it('round-trips station/thirdParty cursor values', () => {
    const encoded = encodeMergeCursor({ station: 'abc', thirdParty: EXHAUSTED_MARKER });
    expect(decodeMergeCursor(encoded)).toEqual({ station: 'abc', thirdParty: EXHAUSTED_MARKER });
  });

  it('round-trips null values as resume-from-beginning', () => {
    const encoded = encodeMergeCursor({ station: null, thirdParty: 'xyz' });
    expect(decodeMergeCursor(encoded)).toEqual({ station: null, thirdParty: 'xyz' });
  });

  it('defaults to both-null when no cursor is given', () => {
    expect(decodeMergeCursor(null)).toEqual({ station: null, thirdParty: null });
    expect(decodeMergeCursor(undefined)).toEqual({ station: null, thirdParty: null });
  });

  it('defaults to both-null on a malformed cursor rather than throwing', () => {
    expect(decodeMergeCursor('not-valid-base64-json')).toEqual({ station: null, thirdParty: null });
  });

  it('builds a stable per-item cursor from distance+id', () => {
    const a = encodeItemCursor({ distanceMeters: 42, id: 'x1' });
    const b = encodeItemCursor({ distanceMeters: 42, id: 'x1' });
    const c = encodeItemCursor({ distanceMeters: 99, id: 'x1' });
    expect(a).toBe(b);
    expect(a).not.toBe(c);
  });
});
