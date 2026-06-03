import BadRequest from '@app/api/error/errors/BadRequest';
import NotFoundError from '@app/api/error/errors/NotFoundError';
import client from '@app/db/client';
import { buildings, users } from '@app/db/schema';
import { requirePermission } from '@app/helpers/requirePermission';
import { Context } from '@app/middlewares/routeWrapper';
import { UserManagePermission } from '@app/permissions';
import { and, eq } from 'drizzle-orm';
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

  const isSelf: boolean = ctx.token.userId;

  // Require UserManager permission if user is trying to update another
  if (!isSelf) {
    requirePermission(ctx, UserManagePermission);
  }

  const fields = ctx.token.userId === id ? AllowedUpdateFields.self : AllowedUpdateFields.other;
  const updatedFields = _.pick(req.body, fields);

  if (Array.isArray(id)) {
    throw BadRequest;
  }

  const filter = and(eq(buildings.id, ctx.token.buildingId), eq(users.id, id));
  const [user] = await client.update(users).set(updatedFields).where(filter).returning();

  return { user };
}
