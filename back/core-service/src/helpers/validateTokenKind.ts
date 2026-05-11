import BadRequest from '@app/api/error/errors/BadRequest';
import { AccountToken, AuthToken, UserToken } from '@app/types/auth';

export function assertAccountToken(token: AuthToken): asserts token is AuthToken & AccountToken {
  const isAccount = token.tokenKind === 'account';
  if (!isAccount) {
    throw BadRequest;
  }
}

export function assertUserToken(token: AuthToken): asserts token is AuthToken & UserToken {
  const isUser = token.tokenKind === 'user';
  if (!isUser) {
    throw BadRequest;
  }
}
