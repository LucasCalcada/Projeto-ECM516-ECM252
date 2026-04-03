import { Route } from '@app/helpers/routeRegistry';
import pingHandler from './handler';

const route: Route = {
  method: 'get',
  path: '/ping',
  handler: pingHandler,
};
export default route;
