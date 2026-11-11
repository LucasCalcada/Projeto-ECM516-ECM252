import { ids } from './ids';
import { type PostResidencyInsert } from '@app/db/schema/post';

// Posts 2 (festa junina) and 4 (assembleia) have no rows: they target the whole building.
export const postResidencySeedData: PostResidencyInsert[] = [
  {
    postId: '55555555-5555-5555-5555-555555555551',
    residencyId: ids.residencies.ap101,
  },
  {
    postId: '55555555-5555-5555-5555-555555555551',
    residencyId: ids.residencies.ap102,
  },

  {
    postId: '55555555-5555-5555-5555-555555555553',
    residencyId: ids.residencies.ap201,
  },

  {
    postId: '55555555-5555-5555-5555-555555555555',
    residencyId: ids.residencies.ap101,
  },
] as const;
