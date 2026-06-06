import Unauthorized from '@app/middlewares/error/errors/Unauthorized';
import { Context } from '@app/middlewares/routeWrapper';
import _ from 'lodash';

export const CREATE_RESERVATION_PERMISSION = '@reservation:create';
export const VIEW_BUILDING_RESERVATION_PERMISSION = '@reservation:view:building';
export const VIEW_RESIDENCY_RESERVATION_PERMISSION = '@reservation:view:residency';

export function requirePermission(ctx: Context, permissions: string[]) {
  const userPermissions = ctx.auth.permissions;
  const allowedPermissions = ['@core:admin', ...permissions];
  const hasPermission = _.intersection(userPermissions, allowedPermissions).length > 0;

  if (!hasPermission) {
    throw Unauthorized;
  }
}
