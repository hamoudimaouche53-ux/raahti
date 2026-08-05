/**
 * Base for every domain-layer exception (docs/architecture/cross-cutting-architecture.md
 * — Error Handling: "DomainException (raised in domain/) ... caught by a global
 * HttpExceptionFilter that maps known DomainException subclasses to their documented
 * code/HTTP status"). Zero framework imports — plain TypeScript, per system-architecture.md §3.
 */
export abstract class DomainException extends Error {
  /** Stable, machine-readable identifier — becomes ProblemDetail.code (api-architecture.md §7). */
  abstract readonly code: string;

  /** HTTP status the global exception filter maps this to. */
  abstract readonly status: number;

  protected constructor(message: string) {
    super(message);
    this.name = new.target.name;
  }
}
