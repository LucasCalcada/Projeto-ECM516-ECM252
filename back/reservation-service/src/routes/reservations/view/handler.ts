import client from '@app/db/client';
import { reservations } from '@app/db/schema/reservation';
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';
import { and, asc, eq, gte } from 'drizzle-orm';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import { todayAsDateString } from '../helpers';
import {
  CREATE_RESERVATION_PERMISSION,
  VIEW_BUILDING_RESERVATION_PERMISSION,
  requirePermission,
} from '@app/helpers/permissions';

export default async function getReservations(req: Request, ctx: Context) {
  requirePermission(ctx, [CREATE_RESERVATION_PERMISSION, VIEW_BUILDING_RESERVATION_PERMISSION]);

  const commonAreaId = req.query.commonAreaId;

  if (typeof commonAreaId !== 'string' || commonAreaId.trim().length === 0) {
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
        eq(reservations.commonAreaId, commonAreaId),
        gte(reservations.reservationDate, todayAsDateString()),
      ),
    )
    .orderBy(asc(reservations.reservationDate));
}
