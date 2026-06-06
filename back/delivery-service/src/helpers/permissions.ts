import Unauthorized from '@app/middlewares/error/errors/Unauthorized';
import { Context } from '@app/middlewares/routeWrapper';
import _ from 'lodash';

export const CREATE_DELIVERY_PERMISSION = '@delivery:create';
export const VIEW_BUILDING_PERMISSION = '@delivery:view:building';
export const VIEW_RESIDENCY_PERMISSION = '@delivery:view:residency';

export function hasPermission(ctx: Context, permission: string) {
  const userPermissions = ctx.auth.permissions;
  if (userPermissions.includes('@core:admin')) {
    return true;
  }

  return userPermissions.includes(permission);
}

export function requirePermission(ctx: Context, permissions: string[]) {
  const userPermissions = ctx.auth.permissions;
  const allowedPermissions = ['@core:admin', ...permissions];
  const hasPermission = _.intersection(userPermissions, allowedPermissions).length > 0;

  if (!hasPermission) {
    throw Unauthorized;
  }
}
