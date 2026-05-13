import { registerRoute } from '@app/helpers/routeRegistry';
import createReservationRoute from './reservations/create/route';
import getMyApartmentReservationsRoute from './reservations/myApartment/route';
import getReservationsRoute from './reservations/view/route';

registerRoute(createReservationRoute);
registerRoute(getMyApartmentReservationsRoute);
registerRoute(getReservationsRoute);
