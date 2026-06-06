import NotFoundError from '@app/api/error/errors/NotFoundError';
import client from '@app/db/client';
import { groups } from '@app/db/schema';
import { assertUserToken } from '@app/helpers/validateTokenKind';
import { Context } from '@app/middlewares/routeWrapper';
import { eq } from 'drizzle-orm';
import { Request } from 'express';

export default async function listGroups(req: Request, ctx: Context) {
  assertUserToken(ctx.token);

  const buildingId = ctx.token.buildingId;

  const buildingGroups = await client.select().from(groups).where(eq(groups.building, buildingId));

  if (!buildingGroups.length) {
    throw NotFoundError;
  }

  return { groups: buildingGroups };
}
