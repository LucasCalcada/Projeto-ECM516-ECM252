import { Request } from 'express';
import { Context } from './routeWrapper';
import jwt, { JwtPayload } from 'jsonwebtoken';
import config from '@app/config';
import Unauthorized from '@app/api/error/errors/Unauthorized';

export default function authMiddleware(req: Request): Context['auth'] {
  const token = req.headers['authorization'];

  if (!token) throw Unauthorized;

  //TODO: use symmetric key for jwt validation
  const result = jwt.verify(token, config.jwtSecret) as JwtPayload;
  const accountId = result['id'];

  if (!accountId) throw Unauthorized;

  return {
    token,
    accountId,
  };
}
