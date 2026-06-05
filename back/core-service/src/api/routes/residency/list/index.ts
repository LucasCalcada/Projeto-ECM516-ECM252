import { Route } from '@app/helpers/routeRegistry';
import handler from './handler';

const route: Route = {
  method: 'get',
  path: '/residencies/list/:groupId',
  handler,
};

export default route;
