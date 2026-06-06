import Unauthorized from '@app/middlewares/error/errors/Unauthorized';
import { Context } from '@app/middlewares/routeWrapper';

export const CREATE_RESERVATION_PERMISSION = '@reservation:create';
export const VIEW_BUILDING_RESERVATION_PERMISSION = '@reservation:view:building';
export const VIEW_RESIDENCY_RESERVATION_PERMISSION = '@reservation:view:residency';

function hasPermission(ctx: Context, permission: string) {
  return ctx.auth.permissions.includes(permission);
}

export function requirePermission(ctx: Context, permission: string) {
  if (!hasPermission(ctx, permission)) {
    throw Unauthorized;
  }
}

export function requireAnyPermission(ctx: Context, permissions: string[]) {
  if (!permissions.some((permission) => hasPermission(ctx, permission))) {
    throw Unauthorized;
  }
}
