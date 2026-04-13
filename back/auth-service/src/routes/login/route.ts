import { Route } from '@app/helpers/routeRegistry';
import authenticateUser from './handler';

const route: Route = {
  method: 'post',
  path: '/auth/login',
  handler: authenticateUser,
};

export default route;
