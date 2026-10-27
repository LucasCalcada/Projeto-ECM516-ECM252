import { Request } from 'express';
import jwt from 'jsonwebtoken';
import config from '@app/config';
import Unauthorized from '@app/api/error/errors/Unauthorized';
import { AuthToken } from '@app/types/auth';

function normalizeAuthorizationHeader(header: string | undefined): string {
  if (!header) throw Unauthorized;
  if (!header.startsWith('Bearer ')) throw Unauthorized;
  return header.slice('Bearer '.length);
}

export function validateAuthToken(req: Request) {
  const token = normalizeAuthorizationHeader(req.headers['authorization']);

  //TODO: use symmetric key for jwt validation
  const result = jwt.verify(token, config.jwtSecret) as AuthToken;

  if (!result.tokenKind) throw Unauthorized;

  return {
    tokenKind: result.tokenKind,
    token: result,
  };
}
