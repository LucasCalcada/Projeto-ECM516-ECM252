import { Route } from '@app/helpers/routeRegistry';
import listAdminPosts from './handler';

const route: Route = {
  method: 'get',
  path: '/posts/admin',
  handler: listAdminPosts,
};

export default route;
