import BadRequest from '@app/api/error/errors/BadRequest';
import NotFoundError from '@app/api/error/errors/NotFoundError';
import client from '@app/db/client';
import { users } from '@app/db/schema';
import { eq } from 'drizzle-orm';
import { Request } from 'express';

export default async function userDelete(req: Request) {
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
