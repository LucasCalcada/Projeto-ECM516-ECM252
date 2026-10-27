import client from '@app/db/client';
import { reservations } from '@app/db/schema/reservation';
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';
import { and, eq } from 'drizzle-orm';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import Conflict from '@app/middlewares/error/errors/Conflict';
import { isValidDateString, todayAsDateString } from '../helpers';
import { CREATE_RESERVATION_PERMISSION, requirePermission } from '@app/helpers/permissions';

export default async function createReservation(req: Request, ctx: Context) {
  requirePermission(ctx, [CREATE_RESERVATION_PERMISSION]);

  const { commonAreaId, commonAreaName, reservationDate } = req.body;

  if (!commonAreaId || !commonAreaName || !reservationDate || !isValidDateString(reservationDate)) {
    throw BadRequest;
  }

  if (reservationDate < todayAsDateString()) {
    throw BadRequest;
  }

  if (!ctx.auth.residencyId) {
    throw BadRequest;
  }

  const existingReservation = await client
    .select({ id: reservations.id })
    .from(reservations)
    .where(
      and(
        eq(reservations.buildingId, ctx.auth.buildingId),
        eq(reservations.commonAreaId, commonAreaId),
        eq(reservations.reservationDate, reservationDate),
      ),
    );

  if (existingReservation.length > 0) {
    throw Conflict;
  }

  const [newReservation] = await client
    .insert(reservations)
    .values({
      userId: ctx.auth.userId,
      residentName: ctx.auth.residencyName ?? ctx.auth.userId,
      residencyId: ctx.auth.residencyId,
      buildingId: ctx.auth.buildingId,
      commonAreaId,
      commonAreaName,
      reservationDate,
    })
    .returning();

  return newReservation;
}
