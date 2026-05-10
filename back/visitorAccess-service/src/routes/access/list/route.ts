import { Route } from '@app/helpers/routeRegistry';
import listAccess from './handler';

const route: Route = {
  method: 'get',
  path: '/access',
  handler: listAccess,
};

export default route;
