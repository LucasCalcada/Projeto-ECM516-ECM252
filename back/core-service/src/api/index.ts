import { registerRoute } from '@helpers/routeRegistry';

import pingRoute from './routes/ping';

// User Routes
import userCreate from './routes/user/create';
import userUpdate from './routes/user/update';
import userDelete from './routes/user/delete';

// Residency Routes
import addResident from './routes/residency/addResident';
import removeResident from './routes/residency/removeResident';
import listResidencyByGroup from './routes/residency/list';
import listResidencyUsers from './routes/residency/listResidents';

// Group Routes
import groupList from './routes/groups/list';
import groupGet from './routes/groups/get';

// Building Routes
import buildingGet from './routes/building/get';
import buildingGetDeatails from './routes/building/details';

// Account Routes
import accountGet from './routes/account/get';

// Auth Routes
import authGet from './routes/authToken/get';

registerRoute(pingRoute);

// User Routes
registerRoute(userCreate);
registerRoute(userDelete);
registerRoute(userUpdate);

// Residency Routes
registerRoute(addResident);
registerRoute(removeResident);
registerRoute(listResidencyByGroup);
registerRoute(listResidencyUsers);

// Group Routes
registerRoute(groupGet);
registerRoute(groupList);

// Building Routes
registerRoute(buildingGet);
registerRoute(buildingGetDeatails);

// Account Routes
registerRoute(accountGet);

// Auth Routes
registerRoute(authGet);
