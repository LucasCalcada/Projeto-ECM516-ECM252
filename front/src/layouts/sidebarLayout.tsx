import { Outlet, useLocation } from 'react-router';
import Sidebar from '../components/sidebar';
import { useEffect, useRef } from 'react';
import { Menu, X } from 'lucide-react';
import { useTranslation } from 'react-i18next';

export default function SidebarLayout() {
  const { t } = useTranslation();
  const drawer = useRef<HTMLDialogElement>(null);
  const trigger = useRef<HTMLButtonElement>(null);
  const location = useLocation();
  useEffect(() => {
    drawer.current?.close();
  }, [location.key]);
  return (
    <div className="app-shell">
      <aside className="app-desktop-sidebar">
        <Sidebar />
      </aside>
      <div className="app-content-frame">
        <header className="app-mobile-header">
          <button
            ref={trigger}
            type="button"
            className="app-navigation-button"
            aria-label={t('sidebar.openMenu')}
            aria-haspopup="dialog"
            onClick={() => drawer.current?.showModal()}
          >
            <Menu size={24} aria-hidden="true" />
          </button>
          <span>HiveApp</span>
        </header>
        <main className="app-content">
          <Outlet />
        </main>
      </div>
      <dialog
        ref={drawer}
        className="app-mobile-drawer"
        aria-label={t('sidebar.navigation')}
        onClose={() => trigger.current?.focus()}
        onClick={(event) => {
          if (event.target instanceof Element && event.target.closest('a')) drawer.current?.close();
        }}
      >
        <button
          type="button"
          className="app-navigation-button app-drawer-close"
          aria-label={t('sidebar.closeMenu')}
          onClick={() => drawer.current?.close()}
        >
          <X size={24} aria-hidden="true" />
        </button>
        <Sidebar />
      </dialog>
    </div>
  );
}
