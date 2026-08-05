export const DELAY_FN = Symbol('DELAY_FN');

export type DelayFn = (ms: number) => Promise<void>;

/** Real production delay — overridden in tests with an instant no-op so retry/backoff tests don't actually wait. */
export const realDelay: DelayFn = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
