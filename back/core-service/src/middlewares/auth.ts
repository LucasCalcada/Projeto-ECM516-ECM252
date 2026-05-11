import { Request } from 'express';
import jwt from 'jsonwebtoken';
import config from '@app/config';
import Unauthorized from '@app/api/error/errors/Unauthorized';
import { AuthToken } from '@app/types/auth';

export function validateAuthToken(req: Request) {
  const token = req.headers['authorization'];

  if (!token) throw Unauthorized;

  //TODO: use symmetric key for jwt validation
  const result = jwt.verify(token, config.jwtSecret) as AuthToken;

  if (!result.tokenKind) throw Unauthorized;

  return {
    tokenKind: result.tokenKind,
    token: result,
  };
}
