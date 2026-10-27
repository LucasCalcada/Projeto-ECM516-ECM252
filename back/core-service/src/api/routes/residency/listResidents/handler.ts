import client from '@app/db/client';
import { users } from '@app/db/schema';
import { assertUserToken } from '@app/helpers/validateTokenKind';
import { Context } from '@app/middlewares/routeWrapper';
import { eq } from 'drizzle-orm';
import { Request } from 'express';

export default async function getResidents(req: Request, ctx: Context) {
  assertUserToken(ctx.token);

  const { residencyId } = req.params;

  const residencyUsers = await client
    .select()
    .from(users)
    .where(eq(users.residencyId, residencyId as string));

  return { users: residencyUsers };
}
