import client from '@app/db/client';
import { visitorAccesses } from '@app/db/schema/access';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';

export default async function registerAccess(req: Request, ctx: Context) {
  const { residencyId, rg, cpf, name, entryAt } = req.body;

  const isMissing = [residencyId, rg, cpf, name].some(
    (v) => v === undefined || v === null || v === '',
  );

  if (isMissing) {
    throw BadRequest;
  }

  const parsedEntryAt = entryAt ? new Date(entryAt) : new Date();

  if (Number.isNaN(parsedEntryAt.getTime())) {
    throw BadRequest;
  }

  const [created] = await client
    .insert(visitorAccesses)
    .values({
      residencyId,
      rg,
      cpf,
      name,
      entryAt: parsedEntryAt,
    })
    .returning();

  return created;
}
