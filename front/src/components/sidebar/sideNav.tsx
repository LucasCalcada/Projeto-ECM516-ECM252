import { NavLink, type NavLinkRenderProps } from 'react-router';
import type { RouteConfig, VisibleRouteConfig } from '../../routes/route';
import routes from '../../routes';
import { useTranslation } from 'react-i18next';
import hasPermission from '../../helpers/hasPermission';
import { LucideLock } from 'lucide-react';

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

  const enabled = props.route.permissions ? hasPermission(props.route.permissions) : true;

  const content = (
    <div className="flex min-h-11 items-center gap-2 px-3 py-2">
      <route.display.icon size="16"></route.display.icon>
      <p className="select-none">{t(route.display.labelKey)}</p>
      {enabled ? null : <LucideLock className="ml-auto" size={16} />}
    </div>
  );

  return enabled ? (
    <NavLink to={route.path} className={highlight}>
      {content}
    </NavLink>
  ) : (
    <div className="rounded-md hover:bg-neutral-800/50">{content}</div>
  );
}

export default function SideNav() {
  const { t } = useTranslation();
  const visibleRoutes: VisibleRouteConfig[] = routes
    .filter((r): r is VisibleRouteConfig => r.visible)
    .filter((r) => !r.hideWithoutPermission || !r.permissions || hasPermission(r.permissions));
  return (
    <nav className="flex flex-col gap-2" aria-label={t('sidebar.navigation')}>
      {visibleRoutes.map((r: RouteConfig) => (
        <NavEntry key={r.path} route={r as VisibleRouteConfig} />
      ))}
    </nav>
  );
}
