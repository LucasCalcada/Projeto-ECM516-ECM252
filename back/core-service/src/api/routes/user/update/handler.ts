import BadRequest from '@app/api/error/errors/BadRequest';
import NotFoundError from '@app/api/error/errors/NotFoundError';
import client from '@app/db/client';
import { users } from '@app/db/schema';
import { Context } from '@app/middlewares/routeWrapper';
import { eq } from 'drizzle-orm';
import { Request } from 'express';
import _ from 'lodash';

const AllowedUpdateFields = {
  self: ['name'],
  other: ['name', 'permissions', 'residencyId'],
};

export default async function userUpdate(req: Request, ctx: Context) {
  const { id } = req.params;

  if (!id) {
    throw NotFoundError;
  }

  const fields = ctx.token.userId === id ? AllowedUpdateFields.self : AllowedUpdateFields.other;
  const updatedFields = _.pick(req.body, fields);

  if (Array.isArray(id)) {
    throw BadRequest;
  }

  const [user] = await client.update(users).set(updatedFields).where(eq(users.id, id)).returning();

  return { user };
}
