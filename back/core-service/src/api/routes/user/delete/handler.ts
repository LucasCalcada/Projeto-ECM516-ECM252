import BadRequest from '@app/api/error/errors/BadRequest';
import NotFoundError from '@app/api/error/errors/NotFoundError';
import client from '@app/db/client';
import { users } from '@app/db/schema';
import { requirePermission } from '@app/helpers/requirePermission';
import { Context } from '@app/middlewares/routeWrapper';
import { UserManagePermission } from '@app/permissions';
import { eq } from 'drizzle-orm';
import { Request } from 'express';

export default async function userDelete(req: Request, ctx: Context) {
  requirePermission(ctx, UserManagePermission);
  const { id } = req.params;

  if (!id) {
    throw NotFoundError;
  }

  if (Array.isArray(id)) {
    throw BadRequest;
  }

  const [user] = await client
    .update(users)
    .set({
      active: false,
    })
    .where(eq(users.id, id))
    .returning();

  return { user };
}
