import client from '@app/db/client';
import { reservations } from '@app/db/schema/reservation';
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';
import { and, asc, eq, gte } from 'drizzle-orm';
import { getAccountData, todayAsDateString } from '../helpers';

export default async function getMyApartmentReservations(req: Request, ctx: Context) {
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
        eq(reservations.residencyId, account.residencyId),
        eq(reservations.status, 'CONFIRMED'),
        gte(reservations.reservationDate, todayAsDateString()),
      ),
    )
    .orderBy(asc(reservations.reservationDate));
}
