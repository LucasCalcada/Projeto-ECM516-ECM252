import { registerRoute } from '@app/helpers/routeRegistry';

import registerAccessRoute from './access/register/route';
import listAccessRoute from './access/list/route';

registerRoute(registerAccessRoute);
registerRoute(listAccessRoute);
