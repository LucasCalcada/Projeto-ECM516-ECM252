import Unauthorized from '@app/middlewares/error/errors/Unauthorized';
import { Context } from '@app/middlewares/routeWrapper';

export const VIEW_VISITOR_PERMISSION = '@visitor:view';
export const CREATE_VISITOR_PERMISSION = '@visitor:create';

export function requirePermission(ctx: Context, permission: string) {
  if (!ctx.auth.permissions.includes(permission)) {
    throw Unauthorized;
  }
}
