import { Route } from '@app/helpers/routeRegistry';
import userDelete from './handler';

const route: Route = {
  method: 'delete',
  path: '/user/:id',
  handler: userDelete,
};

export default route;
