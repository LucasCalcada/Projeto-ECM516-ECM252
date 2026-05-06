import { Route } from '@app/helpers/routeRegistry';
import registerAccess from './handler';

const route: Route = {
  method: 'post',
  path: '/access/register',
  handler: registerAccess,
};

export default route;
