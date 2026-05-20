import config from '@app/config';
import { Context } from '@app/middlewares/routeWrapper';
import Unauthorized from '@app/middlewares/error/errors/Unauthorized';
import jwt, { JwtPayload } from 'jsonwebtoken';

export interface AccountData {
  userId: string;
  buildingId: string;
  residencyId: string;
  residencyName: string | null;
}

interface UserToken extends JwtPayload {
  tokenKind: 'user';
  userId: string;
  buildingId?: string | null;
  residencyId?: string | null;
}

function getSelectedUserToken(ctx: Context): UserToken {
  const rawToken = ctx.req.headers['x-user-token'];
  const token = Array.isArray(rawToken) ? rawToken[0] : rawToken;

  if (!token) {
    throw Unauthorized;
  }

  const decoded = jwt.verify(token, config.jwtSecret) as JwtPayload;

  if (decoded['tokenKind'] !== 'user' || typeof decoded['userId'] !== 'string') {
    throw Unauthorized;
  }

  return {
    ...decoded,
    tokenKind: 'user',
    userId: decoded['userId'],
    buildingId: typeof decoded['buildingId'] === 'string' ? decoded['buildingId'] : null,
    residencyId: typeof decoded['residencyId'] === 'string' ? decoded['residencyId'] : null,
  };
}

export async function getAccountData(ctx: Context): Promise<AccountData> {
  const selectedUser = getSelectedUserToken(ctx);

  const response = await fetch(`${config.coreUrl}/account`, {
    headers: {
      Authorization: ctx.auth.token,
    },
  });

  if (!response.ok) {
    throw Unauthorized;
  }

  const data = (await response.json()) as Partial<AccountData>[] | undefined;
  const userData = data?.find((accountUser) => accountUser.userId === selectedUser.userId);

  const buildingId = userData?.buildingId ?? selectedUser.buildingId;
  const residencyId = userData?.residencyId ?? selectedUser.residencyId;

  if (!userData?.userId || !buildingId || !residencyId) {
    throw Unauthorized;
  }

  return {
    userId: userData.userId,
    buildingId,
    residencyId,
    residencyName: typeof userData.residencyName === 'string' ? userData.residencyName : null,
  };
}
