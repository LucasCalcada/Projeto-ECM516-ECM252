import Unauthorized from '@app/api/error/errors/Unauthorized';
import { Context } from '@app/middlewares/routeWrapper';
import { AdminPermission } from '@app/permissions';
import _ from 'lodash';

export function requirePermission(ctx: Context, permission: string) {
  const permissions = ctx.token.permissions;
  const allowedPermissions = [AdminPermission, permission];
  const hasPermission = _.intersection(permissions, allowedPermissions).length > 0;

  if (!hasPermission) {
    throw Unauthorized;
  }
}
