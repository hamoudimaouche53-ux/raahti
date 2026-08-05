import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { AuthenticatedPrincipal } from './authenticated-principal';

/** Extracts the verified principal attached to the request by JwtAuthGuard (identity module). */
export const CurrentUser = createParamDecorator((_data: unknown, ctx: ExecutionContext): AuthenticatedPrincipal => {
  const request = ctx.switchToHttp().getRequest();
  return request.user;
});
