import { Route } from '@app/helpers/routeRegistry';
import listUserPosts from './handler';

const route: Route = {
  method: 'get',
  path: '/posts',
  handler: listUserPosts,
};

export default route;
