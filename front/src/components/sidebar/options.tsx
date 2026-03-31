import { LogOut, Settings } from 'lucide-react';
import { NavLink } from 'react-router';
import { useTranslation } from 'react-i18next';

export default function Options() {
  const { t } = useTranslation();
  
  return (
    <div className="flex flex-col gap-2 p-1 px-3 pt-4 border-t-1 border-neutral-800 mt-auto">
      <NavLink 
        to="/settings"
        className={({ isActive }) => isActive ? 'bg-neutral-800 rounded-md' : ''}
      >
        <div className="p-1 px-3 flex gap-2 items-center hover:bg-neutral-800/50 rounded-md transition cursor-pointer">
          <Settings size="16" />
          <p>{t('sidebar.options.settings')}</p>
        </div>
      </NavLink>
      
      <div className="flex gap-2 items-center p-1 px-3 hover:bg-neutral-800/50 rounded-md transition cursor-pointer">
        <LogOut size="16" />
        <p>{t('sidebar.options.logout')}</p>
      </div>
    </div>
  );
}
