import { Megaphone } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import NotificationCreateForm from '../components/notifications/NotificationCreateForm';
import hasPermission from '../helpers/hasPermission';

const MANAGE_NOTIFICATIONS_PERMISSION = '@communication:post:manage';

// Residents read notifications on the Home page; this page is only for
// users allowed to send them.
export default function NotificationsView() {
  const { t } = useTranslation();

  if (!hasPermission([MANAGE_NOTIFICATIONS_PERMISSION])) {
    return (
      <div className="flex h-screen items-center justify-center">
        <h1 className="text-2xl font-bold text-neutral-100">{t('common:accessDenied')}</h1>
      </div>
    );
  }

  return (
    <div className="h-full overflow-auto p-4 md:p-8">
      <header className="mb-6 flex items-center gap-2 text-cyan-300">
        <Megaphone size={22} />
        <h1 className="text-2xl font-bold text-neutral-100">{t('notifications:title')}</h1>
      </header>
      <NotificationCreateForm />
    </div>
  );
}
