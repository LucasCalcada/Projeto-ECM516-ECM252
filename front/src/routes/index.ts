import {
  CalendarCheck2,
  HomeIcon,
  ShieldCheck,
  UserRound,
  Settings as SettingsIcon,
  PackageIcon,
} from 'lucide-react';
import Home from '../views/Home';
import Residents from '../views/Residents';
import Login from '../views/Login';
import Reservations from '../views/Reservations';
import Settings from '../views/Settings';
import Portaria from '../views/Portaria';
import Packages from '../views/Packages';
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
    path: '/portaria',
    viewComponent: Portaria,
    layout: 'sidebar',
    visible: true,
    display: {
      labelKey: 'sidebar.routes.portaria',
      icon: ShieldCheck,
    },
  },
  {
    path: '/packages',
    viewComponent: Packages,
    layout: 'sidebar',
    visible: true,
    display: {
      labelKey: 'sidebar.routes.packages',
      icon: PackageIcon,
    },
  },
  {
    path: '/settings',
    viewComponent: Settings,
    layout: 'sidebar',
    visible: false,
    display: {
      labelKey: 'sidebar.routes.settings',
      icon: SettingsIcon,
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
