import Unauthorized from '@app/middlewares/error/errors/Unauthorized';
import { Context } from '@app/middlewares/routeWrapper';

export const MANAGE_COMMUNICATION_POSTS_PERMISSION = '@communication:post:manage';

export function requirePermission(ctx: Context, permission: string) {
  if (!ctx.auth.permissions.includes(permission)) {
    throw Unauthorized;
  }
}
