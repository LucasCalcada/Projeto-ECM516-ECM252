import client from '@app/db/client';
import { visitorAccesses } from '@app/db/schema/access';
import { Context } from '@app/middlewares/routeWrapper';
import { desc, eq } from 'drizzle-orm';
import { Request } from 'express';
import { VIEW_VISITOR_PERMISSION, requirePermission } from '@app/helpers/permissions';

export default async function listAccess(req: Request, ctx: Context) {
  requirePermission(ctx, [VIEW_VISITOR_PERMISSION]);

  return client
    .select()
    .from(visitorAccesses)
    .where(eq(visitorAccesses.buildingId, ctx.auth.buildingId))
    .orderBy(desc(visitorAccesses.entryAt));
}
