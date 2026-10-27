import NotFoundError from '@app/api/error/errors/NotFoundError';
import client from '@app/db/client';
import { buildings } from '@app/db/schema';
import { users } from '@app/db/schema/user';
import { Request } from 'express';
import { eq } from 'drizzle-orm';
import { Context } from '@app/middlewares/routeWrapper';
import { requirePermission } from '@app/helpers/requirePermission';
import { UserManagePermission } from '@app/permissions';

export default async function userCreate(req: Request, ctx: Context) {
  requirePermission(ctx, UserManagePermission);
  const { buildingId, residencyId, name, permissions } = req.body;

  const [building] = await client.select().from(buildings).where(eq(buildings.id, buildingId));

  if (!building) {
    throw NotFoundError;
  }

  const [user] = await client
    .insert(users)
    .values({
      name,
      permissions,
      buildingId,
      residencyId,
      active: true,
    })
    .returning();

  return { user };
}
