import { registerRoute } from '@app/helpers/routeRegistry';

import subscribeRoute from './subscribe';
import unsubscribeRoute from './unsubscribe';
import publishRoute from './publish';

registerRoute(subscribeRoute);
registerRoute(unsubscribeRoute);
registerRoute(publishRoute);
