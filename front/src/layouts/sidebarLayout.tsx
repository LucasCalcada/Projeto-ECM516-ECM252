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
    <div className="flex h-dvh w-full min-w-0 [&_a]:focus-visible:outline-2 [&_a]:focus-visible:outline-offset-2 [&_a]:focus-visible:outline-cyan-300 [&_nav_button]:focus-visible:outline-2 [&_nav_button]:focus-visible:outline-offset-2 [&_nav_button]:focus-visible:outline-cyan-300">
      <aside className="hidden h-full w-56 shrink-0 md:block">
        <Sidebar />
      </aside>
      <div className="flex min-h-0 min-w-0 flex-1 flex-col">
        <header className="flex shrink-0 items-center gap-3 bg-neutral-900 px-3 py-1 font-semibold md:hidden">
          <button
            ref={trigger}
            type="button"
            className="inline-flex min-h-11 min-w-11 cursor-pointer items-center justify-center rounded-md text-neutral-100 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300"
            aria-label={t('sidebar.openMenu')}
            aria-haspopup="dialog"
            onClick={() => drawer.current?.showModal()}
          >
            <Menu size={24} aria-hidden="true" />
          </button>
          <span>HiveApp</span>
        </header>
        <main className="@container/app-content min-h-0 w-full min-w-0 flex-1 overflow-auto">
          <Outlet />
        </main>
      </div>
      <dialog
        ref={drawer}
        className="m-0 h-dvh max-h-dvh w-[88vw] max-w-70 border-0 bg-neutral-900 pt-11 text-neutral-300 backdrop:bg-black/60"
        aria-label={t('sidebar.navigation')}
        onClose={() => trigger.current?.focus()}
        onClick={(event) => {
          if (event.target instanceof Element && event.target.closest('a')) drawer.current?.close();
        }}
      >
        <button
          type="button"
          className="absolute top-0 right-0 inline-flex min-h-11 min-w-11 cursor-pointer items-center justify-center rounded-md text-neutral-100 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan-300"
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
