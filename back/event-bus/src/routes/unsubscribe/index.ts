import { Route } from '@app/helpers/routeRegistry';
import handleUnsubscribeRoute from './handler';

const unsubscribeRoute: Route = {
  method: 'post',
  path: '/events/unsubscribe',
  handler: handleUnsubscribeRoute,
};

export default unsubscribeRoute;
