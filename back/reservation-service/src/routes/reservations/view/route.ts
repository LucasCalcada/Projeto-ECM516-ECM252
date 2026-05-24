import { Route } from '@app/helpers/routeRegistry';
import getReservations from './handler';

const route: Route = {
  method: 'get',
  path: '/reservations',
  handler: getReservations,
};

export default route;
