import { Route } from '@app/helpers/routeRegistry';
import getBuildingDetails from './handler';

const route: Route = {
  method: 'get',
  path: '/building/:id/details',
  handler: getBuildingDetails,
};

export default route;
