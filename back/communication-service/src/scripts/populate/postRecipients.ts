import { ids } from './ids';
import { type PostRecipientInsert } from '@app/db/schema/post';

export const postRecipientSeedData: PostRecipientInsert[] = [
  {
    postId: '55555555-5555-5555-5555-555555555551',
    userId: ids.accounts.maria,
  },
  {
    postId: '55555555-5555-5555-5555-555555555551',
    userId: ids.accounts.carlos,
  },
  {
    postId: '55555555-5555-5555-5555-555555555551',
    userId: ids.accounts.ana,
  },

  {
    postId: '55555555-5555-5555-5555-555555555552',
    userId: ids.accounts.joao,
  },
  {
    postId: '55555555-5555-5555-5555-555555555552',
    userId: ids.accounts.pedro,
  },
  {
    postId: '55555555-5555-5555-5555-555555555552',
    userId: ids.accounts.fernanda,
  },

  {
    postId: '55555555-5555-5555-5555-555555555553',
    userId: ids.accounts.joao,
  },
  {
    postId: '55555555-5555-5555-5555-555555555553',
    userId: ids.accounts.maria,
  },
  {
    postId: '55555555-5555-5555-5555-555555555553',
    userId: ids.accounts.pedro,
  },

  {
    postId: '55555555-5555-5555-5555-555555555554',
    userId: ids.accounts.joao,
  },
  {
    postId: '55555555-5555-5555-5555-555555555554',
    userId: ids.accounts.maria,
  },
  {
    postId: '55555555-5555-5555-5555-555555555554',
    userId: ids.accounts.fernanda,
  },

  {
    postId: '55555555-5555-5555-5555-555555555555',
    userId: ids.accounts.ana,
  },
  {
    postId: '55555555-5555-5555-5555-555555555555',
    userId: ids.accounts.carlos,
  },
] as const;
