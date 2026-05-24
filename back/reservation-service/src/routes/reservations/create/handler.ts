import client from '@app/db/client';
import { reservations } from '@app/db/schema/reservation';
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';
import { and, eq } from 'drizzle-orm';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import Conflict from '@app/middlewares/error/errors/Conflict';
import {
  buildApartmentLabel,
  getAccountData,
  isValidDateString,
  todayAsDateString,
} from '../helpers';

export default async function createReservation(req: Request, ctx: Context) {
  const { commonAreaId, commonAreaName, reservationDate, notes } = req.body;

  if (!commonAreaId || !commonAreaName || !reservationDate || !isValidDateString(reservationDate)) {
    throw BadRequest;
  }

  if (reservationDate < todayAsDateString()) {
    throw BadRequest;
  }

  const account = await getAccountData(ctx);

  const existingReservation = await client
    .select({ id: reservations.id })
    .from(reservations)
    .where(
      and(
        eq(reservations.buildingId, account.buildingId),
        eq(reservations.commonAreaId, commonAreaId),
        eq(reservations.reservationDate, reservationDate),
        eq(reservations.status, 'CONFIRMED'),
      ),
    );

  if (existingReservation.length > 0) {
    throw Conflict;
  }

  const [newReservation] = await client
    .insert(reservations)
    .values({
      userId: account.userId,
      accountId: ctx.auth.accountId,
      residentName: account.userName,
      residencyId: account.residencyId,
      apartment: buildApartmentLabel(account),
      buildingId: account.buildingId,
      buildingName: account.buildingName,
      commonAreaId,
      commonAreaName,
      reservationDate,
      notes: typeof notes === 'string' && notes.trim() ? notes.trim() : null,
      status: 'CONFIRMED',
    })
    .returning();

  return newReservation;
}
