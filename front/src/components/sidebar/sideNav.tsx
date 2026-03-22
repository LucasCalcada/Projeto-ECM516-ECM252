import { NavLink, type NavLinkRenderProps } from "react-router";
import type { RouteConfig, VisibleRouteConfig } from "../../routes/route";
import routes from "../../routes";

function highlight(link: NavLinkRenderProps): string {
  if (link.isActive) {
    return "bg-neutral-800 rounded-md";
  }
  return "";
}

interface NavEntryProps {
  route: VisibleRouteConfig;
}

function NavEntry(props: NavEntryProps) {
  const { route } = props;

  return (
    <NavLink to={route.path} className={highlight}>
      <div className="p-1 px-3 text-neutral-300 flex gap-2 items-center">
        <route.display.icon size="16"></route.display.icon>
        <p>{route.display.label}</p>
      </div>
    </NavLink>
  );
}

export default function SideNav() {
  const visibleRoutes: VisibleRouteConfig[] = routes.filter((r) => r.visible);
  return (
    <nav className="flex flex-col gap-2 flex-1">
      {visibleRoutes.map((r: RouteConfig) => (
        <NavEntry route={r as VisibleRouteConfig} />
      ))}
    </nav>
  );
}
