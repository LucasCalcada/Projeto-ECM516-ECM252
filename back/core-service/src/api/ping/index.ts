import { Route } from '../routeRegistry';
import pingHandler from './handler';

const route: Route = {
  method: 'get',
  path: '/ping',
  handler: pingHandler,
};
export default route;
