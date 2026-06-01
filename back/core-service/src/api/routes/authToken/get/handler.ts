import client from '@app/db/client';
import { residencies, users } from '@app/db/schema';
import jwt from 'jsonwebtoken';
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';
import { eq } from 'drizzle-orm';
import BadRequest from '@app/api/error/errors/BadRequest';
import config from '@app/config';

export default async function getUserToken(req: Request, ctx: Context) {
  const userId = ctx.req.query['userId'] as string;

  if (!userId) {
    throw BadRequest;
  }

  const [user] = await client
    .select({
      id: users.id,
      buildingId: users.buildingId,
      residencyId: users.residencyId,
      residencyName: residencies.name,
      permissions: users.permissions,
    })
    .from(users)
    .leftJoin(residencies, eq(users.residencyId, residencies.id))
    .where(eq(users.id, userId));

  if (!user) {
    throw BadRequest;
  }

  const data = {
    tokenKind: 'user',
    userId: user.id,
    buildingId: user.buildingId,
    residencyId: user.residencyId,
    residencyName: user.residencyName,
    permissions: user.permissions,
  };

  const token = jwt.sign(data, config.jwtSecret, { expiresIn: '1h' });
  return { token };
}
