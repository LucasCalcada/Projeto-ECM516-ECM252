import Unauthorized from '@app/middlewares/error/errors/Unauthorized';
import { Context } from '@app/middlewares/routeWrapper';
import _ from 'lodash';

export const VIEW_VISITOR_PERMISSION = '@visitor:view';
export const CREATE_VISITOR_PERMISSION = '@visitor:create';

export function requirePermission(ctx: Context, permissions: string[]) {
  const userPermissions = ctx.auth.permissions;
  const allowedPermissions = ['@core:admin', ...permissions];
  const hasPermission = _.intersection(userPermissions, allowedPermissions).length > 0;

  if (!hasPermission) {
    throw Unauthorized;
  }
}
