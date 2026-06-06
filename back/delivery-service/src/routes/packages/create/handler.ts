import client from '@app/db/client';
import { packages } from '@app/db/schema/package';
import { CREATE_DELIVERY_PERMISSION, requirePermission } from '@app/helpers/permissions';
import { resolveResidencyByName } from '@app/helpers/residencies';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';

export async function createPackage(req: Request, ctx: Context) {
  requirePermission(ctx, [CREATE_DELIVERY_PERMISSION]);

  const { residencyName, description } = req.body;

  if (!residencyName || !description) {
    throw BadRequest;
  }

  const residency = await resolveResidencyByName(
    ctx.auth.buildingId,
    residencyName,
    ctx.auth.token,
  );

  const [newPackage] = await client
    .insert(packages)
    .values({
      buildingId: ctx.auth.buildingId,
      residencyId: residency.residencyId,
      residencyName: residency.residencyName,
      description,
      status: 'PENDING',
    })
    .returning();

  try {
    await fetch('http://localhost:8004/publish', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        event: 'PACKAGE_ARRIVED',
        data: {
          packageId: newPackage.id,
          residencyId: newPackage.residencyId,
          residencyName: newPackage.residencyName,
          description: newPackage.description,
        },
      }),
    });
  } catch (error) {
    console.error('Falha ao comunicar com o Event Bus', error);
  }

  return newPackage;
}
