import { Route } from '@app/helpers/routeRegistry';
import getAccountData from './handler';

const route: Route = {
  method: 'get',
  path: '/account',
  handler: getAccountData,
};

export default route;
