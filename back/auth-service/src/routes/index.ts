import { registerRoute } from '@app/helpers/routeRegistry';

import createUserRoute from './account/create/route';

registerRoute(createUserRoute);
