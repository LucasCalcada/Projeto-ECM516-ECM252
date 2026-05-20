import client from '@app/db/client';
import { visitorAccesses } from '@app/db/schema/access';
import { Context } from '@app/middlewares/routeWrapper';
import { desc, eq } from 'drizzle-orm';
import { Request } from 'express';
import { getAccountData } from '../helpers';

export default async function listAccess(req: Request, ctx: Context) {
  const account = await getAccountData(ctx);

  return client
    .select()
    .from(visitorAccesses)
    .where(eq(visitorAccesses.buildingId, account.buildingId))
    .orderBy(desc(visitorAccesses.entryAt));
}
