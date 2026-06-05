import NotFoundError from '@app/api/error/errors/NotFoundError';
import client from '@app/db/client';
import { groups, residencies } from '@app/db/schema';
import { assertUserToken } from '@app/helpers/validateTokenKind';
import { Context } from '@app/middlewares/routeWrapper';
import { eq } from 'drizzle-orm';
import { Request } from 'express';

export default async function getGroups(req: Request, ctx: Context) {
  assertUserToken(ctx.token);

  const { groupId } = req.params;

  const [group] = await client
    .select()
    .from(groups)
    .where(eq(groups.id, groupId as string));

  // Check if group is on users' building
  if (group.building !== ctx.token.buildingId) {
    throw NotFoundError;
  }

  const groupResidencies = await client
    .select()
    .from(residencies)
    .where(eq(residencies.groupId, groupId as string));

  if (!groupResidencies.length) {
    throw NotFoundError;
  }

  return { residencies: groupResidencies };
}
