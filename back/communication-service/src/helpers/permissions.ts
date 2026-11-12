import Unauthorized from '@app/middlewares/error/errors/Unauthorized';
import { Context } from '@app/middlewares/routeWrapper';

export const MANAGE_COMMUNICATION_POSTS_PERMISSION = '@communication:post:manage';

export function requirePermission(ctx: Context, permissions: string[]) {
  const userPermissions = ctx.auth.permissions;
  const hasPermission =
    userPermissions.includes('@core:admin') ||
    permissions.some((permission) => userPermissions.includes(permission));

  if (!hasPermission) {
    throw Unauthorized;
  }
}
