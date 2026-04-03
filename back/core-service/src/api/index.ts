import { registerRoute } from '@helpers/routeRegistry';

import pingRoute from './routes/ping';

// User Routes
import userCreate from './routes/user/create';
import userUpdate from './routes/user/update';
import userDelete from './routes/user/delete';

// Residency Routes
import addResident from './routes/residency/addResident';
import removeResident from './routes/residency/removeResident';

registerRoute(pingRoute);

// User Routes
registerRoute(userCreate);
registerRoute(userDelete);
registerRoute(userUpdate);

// Residency Routes
registerRoute(addResident);
registerRoute(removeResident);
