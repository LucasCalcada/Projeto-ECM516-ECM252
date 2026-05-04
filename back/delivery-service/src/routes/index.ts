import { registerRoute } from '@app/helpers/routeRegistry';
import createPackageRoute from './packages/create/route';
import getPackagesByResidencyRoute from './packages/view/route';
import updatePackageRoute from './packages/update/route';
registerRoute(createPackageRoute);
registerRoute(getPackagesByResidencyRoute);
registerRoute(updatePackageRoute);
