import { Route } from '@app/helpers/routeRegistry';
import updatePackageStatus from './handler';

const route: Route = {
  method: 'put',
  path: '/packages', // Ou '/packages/update' se preferir seguir o padrão das outras pastas
  handler: updatePackageStatus,
};

export default route;
