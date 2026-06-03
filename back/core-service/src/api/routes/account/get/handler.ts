import client from '@app/db/client';
import { buildings, users } from '@app/db/schema';
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';
import { eq } from 'drizzle-orm';
import { assertAccountToken } from '@app/helpers/validateTokenKind';

export default async function getAccountData(req: Request, ctx: Context) {
  assertAccountToken(ctx.token);

  const accountId = ctx.token.accountId;

  const result = await client
    .select({
      userId: users.id,
      userName: users.name,
      buildingId: users.buildingId,
      buildingName: buildings.name,
    })
    .from(users)
    .leftJoin(buildings, eq(users.buildingId, buildings.id))
    .where(eq(users.accountId, accountId));

  return result;
}
