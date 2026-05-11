import { Route } from '@app/helpers/routeRegistry';
import getUserToken from './handler';

const route: Route = {
  method: 'get',
  path: '/auth',
  handler: getUserToken,
};

export default route;
