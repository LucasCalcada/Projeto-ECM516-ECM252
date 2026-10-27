import client from '@app/db/client';
import { packages } from '@app/db/schema/package';
import { CREATE_DELIVERY_PERMISSION, requirePermission } from '@app/helpers/permissions';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import { Context } from '@app/middlewares/routeWrapper';
import config from '@app/config';
import { randomUUID } from 'crypto';
import { Request } from 'express';

export async function createPackage(req: Request, ctx: Context) {
  requirePermission(ctx, [CREATE_DELIVERY_PERMISSION]);

  const { residencyId, description } = req.body;

  if (!residencyId || !description) {
    throw BadRequest;
  }

  const [newPackage] = await client
    .insert(packages)
    .values({
      buildingId: ctx.auth.buildingId,
      residencyId,
      description,
      status: 'PENDING',
    })
    .returning();

  try {
    const eventBusResponse = await fetch(`${config.eventBusUrl}/events/PACKAGE_ARRIVED/publish`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        eventId: randomUUID(),
        occurredAt: new Date().toISOString(),
        data: {
          packageId: newPackage.id,
          buildingId: newPackage.buildingId,
          residencyId: newPackage.residencyId,
          description: newPackage.description,
          authorUserId: ctx.auth.userId,
        },
      }),
    });

    if (!eventBusResponse.ok) {
      throw new Error(`Event Bus returned ${eventBusResponse.status}`);
    }
  } catch (error) {
    console.error('Falha ao comunicar com o Event Bus', error);
  }

  return newPackage;
}
