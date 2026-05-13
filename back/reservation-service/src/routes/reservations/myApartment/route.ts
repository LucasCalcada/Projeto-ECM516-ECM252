import { Route } from '@app/helpers/routeRegistry';
import getMyApartmentReservations from './handler';

const route: Route = {
  method: 'get',
  path: '/reservations/my-apartment',
  handler: getMyApartmentReservations,
};

export default route;
