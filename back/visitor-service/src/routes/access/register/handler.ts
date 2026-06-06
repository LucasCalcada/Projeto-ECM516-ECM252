import client from '@app/db/client';
import { visitorAccesses } from '@app/db/schema/access';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';
import { CREATE_VISITOR_PERMISSION, requirePermission } from '@app/helpers/permissions';

export default async function registerAccess(req: Request, ctx: Context) {
  requirePermission(ctx, [CREATE_VISITOR_PERMISSION]);

  const { rg, cpf, name, entryAt } = req.body;

  const isMissing = [rg, cpf, name].some((v) => v === undefined || v === null || v === '');

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
      buildingId: ctx.auth.buildingId,
      residencyId: ctx.auth.residencyId,
      residencyName: ctx.auth.residencyName,
      rg,
      cpf,
      name,
      entryAt: parsedEntryAt,
    })
    .returning();

  return created;
}
