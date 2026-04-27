import BadRequest from '@app/api/error/errors/BadRequest';
import NotFoundError from '@app/api/error/errors/NotFoundError';
import client from '@app/db/client';
import { residencies, users } from '@app/db/schema';
import { Context } from '@app/middlewares/routeWrapper';
import { eq, inArray } from 'drizzle-orm';
import { Request } from 'express';

export default async function addResident(req: Request, ctx: Context) {
  const { residents } = req.body;
  const { id } = req.params;

  if (Array.isArray(id) || !residents) {
    throw BadRequest;
  }

  const [residency] = await client.select().from(residencies).where(eq(residencies.id, id));

  if (!residency) {
    throw NotFoundError;
  }

  const updatedUsers = await client
    .update(users)
    .set({
      residencyId: id,
    })
    .where(inArray(users.id, residents))
    .returning();

  return { users: updatedUsers };
}
