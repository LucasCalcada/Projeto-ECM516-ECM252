import BadRequest from '@app/api/error/errors/BadRequest';
import client from '@app/db/client';
import { users } from '@app/db/schema';
import { inArray } from 'drizzle-orm';
import { Request } from 'express';

export default async function removeResident(req: Request) {
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
