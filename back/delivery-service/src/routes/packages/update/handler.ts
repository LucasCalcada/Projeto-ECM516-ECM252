import deliveryDb from '../../../db/client';
import { packages } from '../../../db/schema/package';
import { VIEW_RESIDENCY_PERMISSION, requirePermission } from '@app/helpers/permissions';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import NotFoundError from '@app/middlewares/error/errors/NotFoundError';
import { Context } from '@app/middlewares/routeWrapper';
import { and, eq } from 'drizzle-orm';
import { Request } from 'express';

function requireResidencyId(ctx: Context) {
  if (!ctx.auth.residencyId) {
    throw BadRequest;
  }

  return ctx.auth.residencyId;
}

export default async function updatePackageStatus(req: Request, ctx: Context) {
  requirePermission(ctx, VIEW_RESIDENCY_PERMISSION);
  const residencyId = requireResidencyId(ctx);

  const { packageId } = req.body;
  if (!packageId) {
    throw BadRequest;
  }

  const result = await deliveryDb
    .update(packages)
    .set({
      status: 'DELIVERED',
      deliveredAt: new Date(),
    })
    .where(
      and(
        eq(packages.id, packageId),
        eq(packages.buildingId, ctx.auth.buildingId),
        eq(packages.residencyId, residencyId),
      ),
    )
    .returning();

  if (result.length === 0) {
    throw NotFoundError;
  }

  return result[0];
}
