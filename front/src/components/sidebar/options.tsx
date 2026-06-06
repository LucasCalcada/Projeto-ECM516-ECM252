import { LogOut, Settings } from 'lucide-react';
import { NavLink, useNavigate } from 'react-router';
import { useTranslation } from 'react-i18next';

export default function Options() {
  const { t } = useTranslation();
  const navigate = useNavigate();

  function handleLogout() {
    localStorage.removeItem('accountToken');
    localStorage.removeItem('userToken');
    localStorage.removeItem('permissions');
    localStorage.removeItem('buildingId');
    localStorage.removeItem('residencyId');
    localStorage.removeItem('residencyName');
    localStorage.removeItem('accessToken');
    localStorage.removeItem('userProfile');

    navigate('/login', { replace: true });
  }

  return (
    <div className="flex flex-col gap-2 border-t-1 border-neutral-800 p-1 px-3 pt-4">
      <NavLink
        to="/settings"
        className={({ isActive }) => (isActive ? 'rounded-md bg-neutral-800' : '')}
      >
        <div className="flex cursor-pointer items-center gap-2 rounded-md p-1 px-3 transition hover:bg-neutral-800/50">
          <Settings size="16" />
          <p>{t('sidebar.options.settings')}</p>
        </div>
      </NavLink>

      <button
        type="button"
        className="flex cursor-pointer items-center gap-2 rounded-md p-1 px-3 text-left transition hover:bg-neutral-800/50"
        onClick={handleLogout}
      >
        <LogOut size="16" />
        <p>{t('sidebar.options.logout')}</p>
      </button>
    </div>
  );
}
