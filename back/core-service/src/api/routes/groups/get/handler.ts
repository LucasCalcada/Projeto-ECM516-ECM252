import NotFoundError from '@app/api/error/errors/NotFoundError';
import client from '@app/db/client';
import { groups } from '@app/db/schema';
import { assertUserToken } from '@app/helpers/validateTokenKind';
import { Context } from '@app/middlewares/routeWrapper';
import { and, eq } from 'drizzle-orm';
import { Request } from 'express';

export default async function getGroups(req: Request, ctx: Context) {
  assertUserToken(ctx.token);
  const buildingId = ctx.token.buildingId;

  const { id } = req.params;

  const filter = and(eq(groups.building, buildingId), eq(groups.id, id as string));

  const [group] = await client.select().from(groups).where(filter);

  if (!group) {
    throw NotFoundError;
  }

  return { group };
}
