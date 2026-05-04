import { Route } from '../../../helpers/routeRegistry'; // Copie o helper routeRegistry.ts de outro serviço se necessário
import { createPackage } from './handler';

const route: Route = {
  method: 'post',
  path: '/packages',
  handler: createPackage,
};

export default route;
