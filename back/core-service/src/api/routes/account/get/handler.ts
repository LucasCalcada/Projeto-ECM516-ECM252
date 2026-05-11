import client from '@app/db/client';
import { buildings, groups, residencies, users } from '@app/db/schema';
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';
import { eq } from 'drizzle-orm';
import { validateTokenKind } from '@app/helpers/validateTokenKind';

export default async function getAccountData(req: Request, ctx: Context) {
  validateTokenKind(ctx.token, 'account');

  const accountId = ctx.token.accountId;

  const result = await client
    .select({
      userId: users.id,
      userName: users.name,

      buildingName: buildings.name,
      groupName: groups.name,
      residencyName: residencies.name,
      residencyCode: residencies.code,
    })
    .from(users)
    .leftJoin(residencies, eq(users.residencyId, residencies.id))
    .leftJoin(groups, eq(residencies.groupId, groups.id))
    .leftJoin(buildings, eq(groups.building, buildings.id))
    .where(eq(users.accountId, accountId));

  return result;
}
