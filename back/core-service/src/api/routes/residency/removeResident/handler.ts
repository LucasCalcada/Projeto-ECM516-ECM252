import BadRequest from '@app/api/error/errors/BadRequest';
import client from '@app/db/client';
import { users } from '@app/db/schema';
import { Context } from '@app/middlewares/routeWrapper';
import { inArray } from 'drizzle-orm';
import { Request } from 'express';

export default async function removeResident(req: Request, ctx: Context) {
  const { residents } = req.body;

  if (!residents) {
    throw BadRequest;
  }

  const updatedUsers = await client
    .update(users)
    .set({
      residencyId: null,
    })
    .where(inArray(users.id, residents));

  return { users: updatedUsers };
}
