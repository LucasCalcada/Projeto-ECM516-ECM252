import { Route } from '@app/helpers/routeRegistry';
import userCreate from './handler';

const route: Route = {
  method: 'post',
  path: '/user',
  handler: userCreate,
};

export default route;
