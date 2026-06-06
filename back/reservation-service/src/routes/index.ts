import { registerRoute } from '@app/helpers/routeRegistry';
import listCommonAreasRoute from './commonAreas/list/route';
import createReservationRoute from './reservations/create/route';
import getMyApartmentReservationsRoute from './reservations/myApartment/route';
import getReservationsRoute from './reservations/view/route';

registerRoute(listCommonAreasRoute);
registerRoute(createReservationRoute);
registerRoute(getMyApartmentReservationsRoute);
registerRoute(getReservationsRoute);
