import { registerRoute } from '@app/helpers/routeRegistry';
import createPostRoute from './posts/create/route';
import listAdminPostsRoute from './posts/listAdmin/route';
import listUserPostsRoute from './posts/listUser/route';
import deletePostRoute from './posts/delete/route';

registerRoute(createPostRoute);
registerRoute(listAdminPostsRoute);
registerRoute(listUserPostsRoute);
registerRoute(deletePostRoute);
