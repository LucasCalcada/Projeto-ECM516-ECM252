import type { LucideIcon } from 'lucide-react';
import type { ComponentType } from 'react';

export interface RouteDisplay {
  labelKey: string;
  icon: LucideIcon;
}

export type RouteLayout = 'sidebar' | 'none';

interface RouteConfigBase {
  path: string;
  viewComponent: ComponentType;
  layout: RouteLayout;
}

export type VisibleRouteConfig = RouteConfigBase & {
  visible: true;
  display: RouteDisplay;
};

export type RouteConfig =
  | VisibleRouteConfig
  | (RouteConfigBase & { visible: false; display?: RouteDisplay });
