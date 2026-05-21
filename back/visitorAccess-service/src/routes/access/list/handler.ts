import client from '@app/db/client';
import { visitorAccesses } from '@app/db/schema/access';
import { Context } from '@app/middlewares/routeWrapper';
import { desc, eq } from 'drizzle-orm';
import { Request } from 'express';
import { assertUserToken } from '@app/helpers/validateTokenKind';

export default async function listAccess(req: Request, ctx: Context) {
  assertUserToken(ctx.token);

  return client
    .select()
    .from(visitorAccesses)
    .where(eq(visitorAccesses.buildingId, ctx.token.buildingId))
    .orderBy(desc(visitorAccesses.entryAt));
}
