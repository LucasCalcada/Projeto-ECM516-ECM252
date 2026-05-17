import { Request } from 'express';
import { Context } from './routeWrapper';
import jwt, { JwtPayload } from 'jsonwebtoken';
import config from '@app/config';
import Unauthorized from './error/errors/Unauthorized';

interface UserToken extends JwtPayload {
  tokenKind: 'user';
  userId: string;
  buildingId: string;
  residencyId: string;
  permissions?: string[];
}

export default function authMiddleware(req: Request): Context['auth'] {
  const authorization = req.headers['authorization'];

  if (!authorization) throw Unauthorized;

  const token = authorization.replace(/^Bearer\s+/i, '');
  const result = jwt.verify(token, config.jwtSecret) as UserToken;

  if (result.tokenKind !== 'user' || !result.userId || !result.buildingId) throw Unauthorized;

  return {
    token,
    userId: result.userId,
    buildingId: result.buildingId,
    residencyId: result.residencyId,
    permissions: result.permissions ?? [],
  };
}
