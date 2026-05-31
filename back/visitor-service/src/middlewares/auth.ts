import { Request } from 'express';
import { Context } from './routeWrapper';
import jwt, { JwtPayload } from 'jsonwebtoken';
import config from '@app/config';
import Unauthorized from './error/errors/Unauthorized';

export default function authMiddleware(req: Request): Context['auth'] {
  const token = req.headers['authorization'];

  if (!token) throw Unauthorized;

  const result = jwt.verify(token, config.jwtSecret) as JwtPayload;
  const accountId = result['accountId'];

  if (result['tokenKind'] !== 'account' || typeof accountId !== 'string') {
    throw Unauthorized;
  }

  return {
    token,
    accountId,
  };
}
