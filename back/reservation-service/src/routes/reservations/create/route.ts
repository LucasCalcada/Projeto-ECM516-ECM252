import { Route } from '@app/helpers/routeRegistry';
import createReservation from './handler';

const route: Route = {
  method: 'post',
  path: '/reservations',
  handler: createReservation,
};

export default route;
