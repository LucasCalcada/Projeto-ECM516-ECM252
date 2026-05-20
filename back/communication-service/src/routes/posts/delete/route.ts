import { Route } from '@app/helpers/routeRegistry';
import deletePost from './handler';

const route: Route = {
  method: 'delete',
  path: '/posts/:id',
  handler: deletePost,
};

export default route;
