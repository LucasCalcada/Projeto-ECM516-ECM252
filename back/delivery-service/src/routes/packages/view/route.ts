import { Route } from '@app/helpers/routeRegistry';
import getPackages from './handler';

const route: Route = {
  method: 'get',
  path: '/packages/view',
  handler: getPackages,
};

export default route;
