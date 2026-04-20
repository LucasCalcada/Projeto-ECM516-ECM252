import { NavLink, type NavLinkRenderProps } from 'react-router';
import type { RouteConfig, VisibleRouteConfig } from '../../routes/route';
import routes from '../../routes';
import { useTranslation } from 'react-i18next';

function highlight(link: NavLinkRenderProps): string {
  if (link.isActive) {
    return 'bg-neutral-800 rounded-md';
  }
  return 'hover:bg-neutral-800/50 rounded-md';
}

interface NavEntryProps {
  route: VisibleRouteConfig;
}

function NavEntry(props: NavEntryProps) {
  const { t } = useTranslation();
  const { route } = props;

  return (
    <NavLink to={route.path} className={highlight}>
      <div className="flex items-center gap-2 p-1 px-3">
        <route.display.icon size="16"></route.display.icon>
        <p>{t(route.display.labelKey)}</p>
      </div>
    </NavLink>
  );
}

export default function SideNav() {
  const visibleRoutes: VisibleRouteConfig[] = routes.filter((r) => r.visible);
  return (
    <nav className="flex flex-1 flex-col gap-2">
      {visibleRoutes.map((r: RouteConfig) => (
        <NavEntry key={r.path} route={r as VisibleRouteConfig} />
      ))}
    </nav>
  );
}
