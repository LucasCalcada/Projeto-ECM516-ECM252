import { Route } from '@app/helpers/routeRegistry';
import updateAccount from './handler';

const route: Route = {
  method: 'put',
  path: '/auth/account',
  handler: updateAccount,
};

export default route;
