import { registerRoute } from '@app/helpers/routeRegistry';

import createUserRoute from './account/create/route';
import authenticateUserRoute from './login/route';

registerRoute(createUserRoute);
registerRoute(authenticateUserRoute);
