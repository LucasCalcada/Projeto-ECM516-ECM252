import { Request } from 'express';
import jwt from 'jsonwebtoken';
import config from '@app/config';
import Unauthorized from './error/errors/Unauthorized';
import { AuthToken } from '@app/types/auth';

export function validateAuthToken(req: Request) {
  const header = req.headers['authorization'];

  if (!header) throw Unauthorized;

  const token = header.startsWith('Bearer ') ? header.slice(7) : header;
  const result = jwt.verify(token, config.jwtSecret) as AuthToken;

  if (!result.tokenKind) throw Unauthorized;

  return {
    tokenKind: result.tokenKind,
    token: result,
  };
}
