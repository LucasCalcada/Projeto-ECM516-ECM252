import { Route } from '@app/helpers/routeRegistry';
import createPost from './handler';

const route: Route = {
  method: 'post',
  path: '/posts',
  handler: createPost,
};

export default route;
