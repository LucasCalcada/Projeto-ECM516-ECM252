import { Request } from 'express';
import { Context } from './routeWrapper';
import jwt, { JwtPayload } from 'jsonwebtoken';
import config from '@app/config';
import Unauthorized from './error/errors/Unauthorized';

export default function authMiddleware(req: Request): Context['auth'] {
  const header = req.headers['authorization'];

  if (!header) throw Unauthorized;

  const token = header.startsWith('Bearer ') ? header.slice(7) : header;

  const result = jwt.verify(token, config.jwtSecret) as JwtPayload;
  const accountId = result['id'];

  if (!accountId) throw Unauthorized;

  return {
    token,
    accountId,
  };
}
