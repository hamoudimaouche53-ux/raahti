/** RFC 7807 (application/problem+json) — api-architecture.md §7. */
export interface ProblemDetail {
  type: string;
  title: string;
  status: number;
  detail: string;
  instance: string;
  code: string;
}
