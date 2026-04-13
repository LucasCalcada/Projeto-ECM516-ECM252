import { Route } from '@app/helpers/routeRegistry';
import createUser from './handler';

const route: Route = {
  method: 'post',
  path: '/auth/account',
  handler: createUser,
};

export default route;
