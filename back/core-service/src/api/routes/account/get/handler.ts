import client from '@app/db/client';
import { buildings, groups, residencies, users } from '@app/db/schema';
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';
import { eq } from 'drizzle-orm';

export default async function getAccountData(req: Request, ctx: Context) {
  const accountId = ctx.auth.accountId;

  const result = await client
    .select({
      userId: users.id,
      userName: users.name,

      buildingId: buildings.id,
      buildingName: buildings.name,

      groupId: groups.id,
      groupName: groups.name,

      residencyId: residencies.id,
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
