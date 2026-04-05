import { Route } from '@app/helpers/routeRegistry';
import userUpdate from './handler';

const route: Route = {
  method: 'put',
  path: '/user/:id',
  handler: userUpdate,
};

export default route;
