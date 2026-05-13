import client from '@app/db/client';
import { reservations } from '@app/db/schema/reservation';
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';
import { and, asc, eq, gte } from 'drizzle-orm';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import { getAccountData, todayAsDateString } from '../helpers';

export default async function getReservations(req: Request, ctx: Context) {
  const commonAreaId = req.query.commonAreaId;

  if (typeof commonAreaId !== 'string' || commonAreaId.trim().length === 0) {
    throw BadRequest;
  }

  const account = await getAccountData(ctx);

  return client
    .select({
      id: reservations.id,
      residentName: reservations.residentName,
      apartment: reservations.apartment,
      buildingName: reservations.buildingName,
      commonAreaId: reservations.commonAreaId,
      commonAreaName: reservations.commonAreaName,
      reservationDate: reservations.reservationDate,
      status: reservations.status,
      notes: reservations.notes,
    })
    .from(reservations)
    .where(
      and(
        eq(reservations.buildingId, account.buildingId),
        eq(reservations.commonAreaId, commonAreaId),
        eq(reservations.status, 'CONFIRMED'),
        gte(reservations.reservationDate, todayAsDateString()),
      ),
    )
    .orderBy(asc(reservations.reservationDate));
}
