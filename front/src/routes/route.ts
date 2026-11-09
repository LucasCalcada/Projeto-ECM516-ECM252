import type { LucideIcon } from 'lucide-react';

export interface RouteDisplay {
  labelKey: string;
  icon: LucideIcon;
}

export type RouteLayout = 'sidebar' | 'none';

interface RouteConfigBase {
  path: string;
  viewComponent: any;
  layout: RouteLayout;
}

export type VisibleRouteConfig = RouteConfigBase & {
  visible: true;
  display: RouteDisplay;
  permissions?: string[];
  // Hide the entry instead of showing it locked when permissions are missing.
  hideWithoutPermission?: boolean;
};

export type RouteConfig =
  | VisibleRouteConfig
  | (RouteConfigBase & { visible: false; display?: RouteDisplay });
