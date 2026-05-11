import Unauthorized from '@app/api/error/errors/Unauthorized';
import { AuthToken, TokenKind } from '@app/types/auth';

export function validateTokenKind(token: AuthToken, tokenKind: TokenKind) {
  if (token.tokenKind === tokenKind) {
    return;
  }

  throw Unauthorized;
}
