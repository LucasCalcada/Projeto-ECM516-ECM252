import { CalendarCheck2, HomeIcon, UserRound } from 'lucide-react';
import Home from '../views/Home';
import Residents from '../views/Residents';
import Login from '../views/Login';
import Reservations from '../views/Reservations';
import type { RouteConfig } from './route';

const routes: RouteConfig[] = [
  {
    path: '/home',
    viewComponent: Home,
    layout: 'sidebar',
    visible: true,
    display: {
      labelKey: 'sidebar.routes.home',
      icon: HomeIcon,
    },
  },
  {
    path: '/residents',
    viewComponent: Residents,
    layout: 'sidebar',
    visible: true,
    display: {
      labelKey: 'sidebar.routes.residents',
      icon: UserRound,
    },
  },
  {
    path: '/reservations',
    viewComponent: Reservations,
    layout: 'sidebar',
    visible: true,
    display: {
      labelKey: 'sidebar.routes.reservations',
      icon: CalendarCheck2,
    },
  },
  {
    path: '/login',
    viewComponent: Login,
    layout: 'none',
    visible: false,
  },
];

export default routes;
