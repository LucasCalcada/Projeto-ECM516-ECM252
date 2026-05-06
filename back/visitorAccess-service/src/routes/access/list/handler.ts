import client from '@app/db/client';
import { visitorAccesses } from '@app/db/schema/access';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import { Context } from '@app/middlewares/routeWrapper';
import { eq } from 'drizzle-orm';
import { Request } from 'express';

export default async function listAccess(req: Request, ctx: Context) {
  const residencyId = req.query.residencyId;

  if (!residencyId || Array.isArray(residencyId)) {
    throw BadRequest;
  }

  const results = await client
    .select()
    .from(visitorAccesses)
    .where(eq(visitorAccesses.residencyId, residencyId));

  return results;
}
