import { Route } from '@app/helpers/routeRegistry';
import handlePublishRoute from './handler';

const publishRoute: Route = {
  method: 'post',
  path: '/events/:eventName/publish',
  handler: handlePublishRoute,
};

export default publishRoute;
