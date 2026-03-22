import type { LucideIcon } from "lucide-react";

export interface RouteDisplay {
  label: string;
  icon: LucideIcon;
}

interface RouteConfigBase {
  path: string;
  viewComponent: any;
}

export type VisibleRouteConfig = RouteConfigBase & {
  visible: true;
  display: RouteDisplay;
};

export type RouteConfig =
  | VisibleRouteConfig
  | (RouteConfigBase & { visible: false });
