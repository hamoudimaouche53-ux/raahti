import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { Request, Response } from 'express';
import { DomainException } from '../../shared-kernel';
import { ProblemDetail } from './problem-detail';

const PROBLEM_TYPE_BASE = 'https://raahti.dev/errors/';

/**
 * Global exception filter — maps every 4xx/5xx to RFC 7807 application/problem+json
 * (api-architecture.md §7, cross-cutting-architecture.md — Error Handling).
 * Unmapped/unexpected exceptions become a generic 500 with a redacted detail
 * (never leaking stack traces or internal identifiers to the client) plus a full
 * server-side log entry tagged with the request's correlation ID.
 */
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    const correlationId = request.headers['x-correlation-id'] as string | undefined;

    const problem = this.toProblemDetail(exception, request.originalUrl ?? request.url);

    if (problem.status >= 500) {
      this.logger.error(
        `[${correlationId ?? 'no-correlation-id'}] ${problem.code}: ${(exception as Error)?.stack ?? exception}`,
      );
    }

    response.status(problem.status).contentType('application/problem+json').json(problem);
  }

  private toProblemDetail(exception: unknown, instance: string): ProblemDetail {
    if (exception instanceof DomainException) {
      return {
        type: `${PROBLEM_TYPE_BASE}${this.slugify(exception.code)}`,
        title: exception.name,
        status: exception.status,
        detail: exception.message,
        instance,
        code: exception.code,
      };
    }

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const body = exception.getResponse();
      const detail = typeof body === 'string' ? body : ((body as { message?: string }).message ?? exception.message);
      return {
        type: `${PROBLEM_TYPE_BASE}${this.slugify(exception.constructor.name)}`,
        title: exception.constructor.name,
        status,
        detail: Array.isArray(detail) ? detail.join('; ') : detail,
        instance,
        code: this.httpStatusCode(status),
      };
    }

    return {
      type: `${PROBLEM_TYPE_BASE}internal-server-error`,
      title: 'Internal Server Error',
      status: HttpStatus.INTERNAL_SERVER_ERROR,
      detail: 'An unexpected error occurred.',
      instance,
      code: 'INTERNAL_SERVER_ERROR',
    };
  }

  private slugify(value: string): string {
    return value
      .replace(/([a-z0-9])([A-Z])/g, '$1-$2')
      .replace(/_/g, '-')
      .toLowerCase();
  }

  private httpStatusCode(status: number): string {
    return HttpStatus[status] ?? `HTTP_${status}`;
  }
}
