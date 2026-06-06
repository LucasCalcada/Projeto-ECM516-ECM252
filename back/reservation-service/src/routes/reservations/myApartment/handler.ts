import client from '@app/db/client';
import { reservations } from '@app/db/schema/reservation';
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';
import { and, asc, eq, gte } from 'drizzle-orm';
import { todayAsDateString } from '../helpers';
import { VIEW_RESIDENCY_RESERVATION_PERMISSION, requirePermission } from '@app/helpers/permissions';
import BadRequest from '@app/middlewares/error/errors/BadRequest';

export default async function getMyApartmentReservations(req: Request, ctx: Context) {
  requirePermission(ctx, [VIEW_RESIDENCY_RESERVATION_PERMISSION]);

  if (!ctx.auth.residencyId) {
    throw BadRequest;
  }

  return client
    .select({
      id: reservations.id,
      residentName: reservations.residentName,
      commonAreaId: reservations.commonAreaId,
      commonAreaName: reservations.commonAreaName,
      reservationDate: reservations.reservationDate,
    })
    .from(reservations)
    .where(
      and(
        eq(reservations.buildingId, ctx.auth.buildingId),
        eq(reservations.residencyId, ctx.auth.residencyId),
        gte(reservations.reservationDate, todayAsDateString()),
      ),
    )
    .orderBy(asc(reservations.reservationDate));
}
