import deliveryDb from '../../../db/client';
import { packages } from '../../../db/schema/package';
import {
  VIEW_BUILDING_PERMISSION,
  VIEW_RESIDENCY_PERMISSION,
  hasPermission,
  requirePermission,
} from '@app/helpers/permissions';
import Unauthorized from '@app/middlewares/error/errors/Unauthorized';
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';
import { desc, eq } from 'drizzle-orm';

function requireResidencyId(ctx: Context) {
  if (!ctx.auth.residencyId) {
    throw Unauthorized;
  }

  return ctx.auth.residencyId;
}

export default async function getPackages(req: Request, ctx: Context) {
  const scope = req.query.scope;

  if (scope === 'building') {
    requirePermission(ctx, [VIEW_BUILDING_PERMISSION]);
    return deliveryDb
      .select()
      .from(packages)
      .where(eq(packages.buildingId, ctx.auth.buildingId))
      .orderBy(desc(packages.createdAt));
  }

  if (scope === 'residency') {
    requirePermission(ctx, [VIEW_RESIDENCY_PERMISSION]);
    const residencyId = requireResidencyId(ctx);

    return deliveryDb
      .select()
      .from(packages)
      .where(eq(packages.residencyId, residencyId))
      .orderBy(desc(packages.createdAt));
  }

  if (scope !== undefined) {
    throw Unauthorized;
  }

  if (hasPermission(ctx, VIEW_BUILDING_PERMISSION)) {
    return deliveryDb
      .select()
      .from(packages)
      .where(eq(packages.buildingId, ctx.auth.buildingId))
      .orderBy(desc(packages.createdAt));
  }

  requirePermission(ctx, [VIEW_RESIDENCY_PERMISSION]);
  const residencyId = requireResidencyId(ctx);

  return deliveryDb
    .select()
    .from(packages)
    .where(eq(packages.residencyId, residencyId))
    .orderBy(desc(packages.createdAt));
}
