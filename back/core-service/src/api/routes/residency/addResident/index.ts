import { Route } from '@app/helpers/routeRegistry';
import addResident from './handler';

const route: Route = {
  method: 'put',
  path: '/residency/:id/addResident',
  handler: addResident,
};

export default route;
