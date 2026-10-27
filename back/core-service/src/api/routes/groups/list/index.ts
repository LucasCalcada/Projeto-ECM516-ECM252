import { Route } from '@app/helpers/routeRegistry';
import handler from './handler';

const route: Route = {
  method: 'get',
  path: '/groups',
  handler,
};

export default route;
