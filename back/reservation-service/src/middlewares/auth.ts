import { Request } from 'express';
import { Context } from './routeWrapper';
import jwt, { JwtPayload } from 'jsonwebtoken';
import config from '@app/config';
import Unauthorized from './error/errors/Unauthorized';

interface UserToken extends JwtPayload {
  tokenKind: 'user';
  userId: string;
  buildingId: string;
  residencyId?: string | null;
  residencyName?: string | null;
  permissions?: string[];
}

function normalizeAuthorizationHeader(header: string | undefined): string {
  if (!header) throw Unauthorized;
  if (!header.startsWith('Bearer ')) throw Unauthorized;
  return header.slice('Bearer '.length);
}

export default function authMiddleware(req: Request): Context['auth'] {
  const token = normalizeAuthorizationHeader(req.headers['authorization']);
  const result = jwt.verify(token, config.jwtSecret) as UserToken;

  if (result.tokenKind !== 'user' || !result.userId || !result.buildingId) throw Unauthorized;

  return {
    userId: result.userId,
    buildingId: result.buildingId,
    residencyId: result.residencyId ?? null,
    residencyName: result.residencyName ?? null,
    permissions: result.permissions ?? [],
  };
}
