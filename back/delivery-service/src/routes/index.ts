import { registerRoute } from '@app/helpers/routeRegistry';
import createPackageRoute from './packages/create/route';
import getPackagesByResidencyRoute from './packages/view/route';
registerRoute(createPackageRoute);
registerRoute(getPackagesByResidencyRoute);