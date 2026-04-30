import BadRequest from '@app/api/error/errors/BadRequest';
import NotFoundError from '@app/api/error/errors/NotFoundError';
import client from '@app/db/client';
import { users } from '@app/db/schema';
import { Context } from '@app/middlewares/routeWrapper';
import { eq } from 'drizzle-orm';
import { Request } from 'express';

export default async function userUpdate(req: Request, ctx: Context) {
  const { id } = req.params;
  const { name, residencyId, buildingId, permissions, accountId } = req.body;

  if (!id) {
    throw NotFoundError;
  }

  if (Array.isArray(id)) {
    throw BadRequest;
  }

  const [user] = await client
    .update(users)
    .set({
      name,
      residencyId,
      buildingId,
      permissions,
      accountId,
    })
    .where(eq(users.id, id))
    .returning();

  return { user };
}
