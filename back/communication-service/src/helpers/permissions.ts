import Unauthorized from '@app/middlewares/error/errors/Unauthorized';
import { Context } from '@app/middlewares/routeWrapper';
import _ from 'lodash';

export const MANAGE_COMMUNICATION_POSTS_PERMISSION = '@communication:post:manage';

export function requirePermission(ctx: Context, permissions: string[]) {
  const userPermissions = ctx.auth.permissions;
  const allowedPermissions = ['@core:admin', ...permissions];
  const hasPermission = _.intersection(allowedPermissions, userPermissions).length > 0;

  if (!hasPermission) {
    throw Unauthorized;
  }
}
