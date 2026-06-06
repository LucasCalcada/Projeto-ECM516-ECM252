import Unauthorized from '@app/middlewares/error/errors/Unauthorized';
import { Context } from '@app/middlewares/routeWrapper';

export const CREATE_DELIVERY_PERMISSION = '@delivery:create';
export const VIEW_BUILDING_PERMISSION = '@delivery:view:building';
export const VIEW_RESIDENCY_PERMISSION = '@delivery:view:residency';

export function hasPermission(ctx: Context, permission: string) {
  return ctx.auth.permissions.includes(permission);
}

export function requirePermission(ctx: Context, permission: string) {
  if (!hasPermission(ctx, permission)) {
    throw Unauthorized;
  }
}
