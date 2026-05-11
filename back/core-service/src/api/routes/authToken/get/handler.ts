import client from '@app/db/client';
import { users } from '@app/db/schema';
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

  const [user] = await client.select().from(users).where(eq(users.id, userId));

  const data = {
    tokenKind: 'user',
    userId: user.id,
    buildingId: user.buildingId,
    residencyId: user.residencyId,
    permissions: user.permissions,
  };

  const token = jwt.sign(data, config.jwtSecret, { expiresIn: '1h' });
  return { token };
}
