import { Route } from '@app/helpers/routeRegistry';
import getBuilding from './handler';

const route: Route = {
  method: 'get',
  path: '/building/:id',
  handler: getBuilding,
};

export default route;
