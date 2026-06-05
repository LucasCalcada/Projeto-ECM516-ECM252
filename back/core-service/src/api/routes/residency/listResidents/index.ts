import { Route } from '@app/helpers/routeRegistry';
import handler from './handler';

const route: Route = {
  method: 'get',
  path: '/residencies/:residencyId/users',
  handler,
};

export default route;
