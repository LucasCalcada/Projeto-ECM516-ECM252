import { Request } from 'express';
import { Context } from '@app/middlewares/routeWrapper';
import client from '@app/db/client';
import { users } from '@app/db/schema';
import { eq } from 'drizzle-orm';
import { requirePermission } from '@app/helpers/requirePermission';
import { UserManagePermission } from '@app/permissions';
import NotFoundError from '@app/api/error/errors/NotFoundError';

export default async function handler(req: Request, ctx: Context) {
  requirePermission(ctx, UserManagePermission);
  const { userId } = req.params;

  const [user] = await client
    .select()
    .from(users)
    .where(eq(users.id, userId as string));

  if (!user) {
    throw NotFoundError;
  }

  return { user };
}
