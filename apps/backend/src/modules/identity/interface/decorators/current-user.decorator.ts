import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { JwtClaims } from '../../infrastructure/auth/jwt-claims';

/** Extracts the verified JWT claims attached to the request by JwtAuthGuard. */
export const CurrentUser = createParamDecorator((_data: unknown, ctx: ExecutionContext): JwtClaims => {
  const request = ctx.switchToHttp().getRequest();
  return request.user;
});
