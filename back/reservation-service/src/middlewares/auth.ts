import { Request } from 'express';
import { Context } from './routeWrapper';
import jwt, { JwtPayload } from 'jsonwebtoken';
import config from '@app/config';
import Unauthorized from './error/errors/Unauthorized';

function normalizeAuthorizationHeader(header: string | undefined): string {
  if (!header) throw Unauthorized;
  return header.startsWith('Bearer ') ? header.slice('Bearer '.length) : header;
}

export default function authMiddleware(req: Request): Context['auth'] {
  const token = normalizeAuthorizationHeader(req.headers['authorization']);
  const result = jwt.verify(token, config.jwtSecret) as JwtPayload;
  const accountId = result['id'];

  if (!accountId) throw Unauthorized;

  return {
    token,
    accountId,
  };
}
