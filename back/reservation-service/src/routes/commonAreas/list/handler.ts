import client from '@app/db/client';
import { commonAreas } from '@app/db/schema/reservation';
import {
  CREATE_RESERVATION_PERMISSION,
  VIEW_BUILDING_RESERVATION_PERMISSION,
  requirePermission,
} from '@app/helpers/permissions';
import { Context } from '@app/middlewares/routeWrapper';
import { asc, eq } from 'drizzle-orm';
import { Request } from 'express';

export default async function listCommonAreas(_req: Request, ctx: Context) {
  requirePermission(ctx, [CREATE_RESERVATION_PERMISSION, VIEW_BUILDING_RESERVATION_PERMISSION]);

  return client
    .select({
      id: commonAreas.id,
      buildingId: commonAreas.buildingId,
      name: commonAreas.name,
      limit: commonAreas.limit,
    })
    .from(commonAreas)
    .where(eq(commonAreas.buildingId, ctx.auth.buildingId))
    .orderBy(asc(commonAreas.name));
}
