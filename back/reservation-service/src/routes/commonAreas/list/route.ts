import { Route } from '@app/helpers/routeRegistry';
import listCommonAreas from './handler';

const route: Route = {
  method: 'get',
  path: '/common-areas',
  handler: listCommonAreas,
};

export default route;
