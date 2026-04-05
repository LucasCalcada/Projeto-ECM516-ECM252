import { Route } from '@app/helpers/routeRegistry';
import removeResident from './handler';

const route: Route = {
  method: 'put',
  path: '/residency/:id/removeResident',
  handler: removeResident,
};

export default route;
