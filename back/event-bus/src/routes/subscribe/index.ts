import { Route } from '@app/helpers/routeRegistry';
import handleSubscribeRoute from './handler';

const subscribeRoute: Route = {
  method: 'post',
  path: '/events/:eventName/subscribe',
  handler: handleSubscribeRoute,
};

export default subscribeRoute;
