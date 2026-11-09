import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import NotificationCreateForm from '../components/notifications/NotificationCreateForm';
import NotificationList from '../components/notifications/NotificationList';
import NotificationsHeader from '../components/notifications/NotificationsHeader';
import type {
  NotificationViewMode,
  NotificationViewOption,
} from '../components/notifications/types';
import hasPermission from '../helpers/hasPermission';

const MANAGE_NOTIFICATIONS_PERMISSION = '@communication:post:manage';

// Every user of the building can read notifications addressed to them;
// creating and managing notifications requires the communication permission.
function getAvailableViews() {
  const options: NotificationViewOption[] = [{ mode: 'inbox' }];

  if (hasPermission([MANAGE_NOTIFICATIONS_PERMISSION])) {
    options.push({ mode: 'create' });
    options.push({ mode: 'manage' });
  }

  return options;
}

function NotificationsInbox() {
  return <NotificationList scope="inbox" />;
}

function NotificationsCreate() {
  return <NotificationCreateForm />;
}

function NotificationsManage() {
  return <NotificationList scope="manage" />;
}

function renderNotificationsView(mode: NotificationViewMode) {
  if (mode === 'create') {
    return <NotificationsCreate />;
  }

  if (mode === 'manage') {
    return <NotificationsManage />;
  }

  return <NotificationsInbox />;
}

export default function NotificationsView() {
  const { t } = useTranslation();
  const options = getAvailableViews();
  const [activeMode, setActiveMode] = useState<NotificationViewMode>(options[0]?.mode ?? 'inbox');
  const currentMode = options.some((option) => option.mode === activeMode)
    ? activeMode
    : options[0]?.mode;

  if (!currentMode) {
    return (
      <div className="flex h-screen items-center justify-center">
        <h1 className="text-2xl font-bold text-neutral-100">{t('common:accessDenied')}</h1>
      </div>
    );
  }

  return (
    <div className="h-full overflow-auto p-4 md:p-8">
      <NotificationsHeader
        activeMode={currentMode}
        options={options}
        onModeChange={setActiveMode}
      />
      {renderNotificationsView(currentMode)}
    </div>
  );
}
