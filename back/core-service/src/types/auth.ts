import { type JwtPayload } from 'jsonwebtoken';

export type TokenKind = 'account' | 'user';

export interface UserToken {
  tokenKind: 'user';
  userId: string;
  buildingId: string;
  residencyId: string;
  permissions: string[];
}

export interface AccountToken {
  tokenKind: 'account';
  accountId: string;
  email: string;
}

export type AuthToken = (UserToken | AccountToken) & JwtPayload;
