import { Injectable, NestMiddleware } from '@nestjs/common';
import { NextFunction, Request, Response } from 'express';
import { randomUUID } from 'crypto';

const HEADER = 'x-correlation-id';

/** Request-tracing correlation IDs (platform README; System Architecture §3). */
@Injectable()
export class CorrelationIdMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction): void {
    const incoming = req.headers[HEADER];
    const correlationId = (Array.isArray(incoming) ? incoming[0] : incoming) || randomUUID();
    req.headers[HEADER] = correlationId;
    res.setHeader(HEADER, correlationId);
    next();
  }
}
