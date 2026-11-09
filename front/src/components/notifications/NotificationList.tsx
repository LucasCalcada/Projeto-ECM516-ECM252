import { useCallback, useEffect, useMemo, useState } from 'react';
import { BellOff, RefreshCw } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { useToast } from '../Toast';
import useService from '../../helpers/useService';
import useResidencies from '../../helpers/useResidencies';
import type Notification from '../../types/Notification';
import NotificationCard from './NotificationCard';

interface NotificationListProps {
  // inbox: notifications addressed to the user; manage: every notification of the building.
  scope: 'inbox' | 'manage';
}

const endpointByScope = {
  inbox: '/posts',
  manage: '/posts/admin',
};

export default function NotificationList({ scope }: NotificationListProps) {
  const { t } = useTranslation();
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const { notifyError, notifySuccess } = useToast();
  const communicationService = useService('communication');
  const isManageScope = scope === 'manage';

  const fetchNotifications = useCallback(async () => {
    setIsLoading(true);
    try {
      const response = await communicationService.get<Notification[]>(endpointByScope[scope]);
      setNotifications(response.data);
    } catch (error) {
      console.error(error);
      notifyError(t('common:error'), t('notifications:list.toast.listError'));
    } finally {
      setIsLoading(false);
    }
  }, [communicationService, notifyError, scope, t]);

  useEffect(() => {
    fetchNotifications();
  }, [fetchNotifications]);

  async function handleDelete(notification: Notification) {
    if (!window.confirm(t('notifications:list.confirmDelete', { title: notification.title }))) {
      return;
    }

    setDeletingId(notification.id);
    try {
      await communicationService.delete(`/posts/${notification.id}`);
      notifySuccess(
        t('notifications:list.toast.deleteTitle'),
        t('notifications:list.toast.deleteMessage'),
      );
      setNotifications((current) => current.filter((item) => item.id !== notification.id));
    } catch (error) {
      console.error(error);
      notifyError(t('common:error'), t('notifications:list.toast.deleteError'));
    } finally {
      setDeletingId(null);
    }
  }

  return (
    <section className="rounded-lg border border-neutral-800 bg-neutral-900/40 p-4">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <button
          type="button"
          className="ml-auto inline-flex items-center gap-2 rounded-md bg-cyan-300 px-3 py-2 text-sm font-semibold text-neutral-950 transition hover:bg-cyan-200 disabled:cursor-not-allowed disabled:opacity-60"
          onClick={fetchNotifications}
          disabled={isLoading}
        >
          <RefreshCw size={16} />
          {isLoading ? t('common:updating') : t('common:refresh')}
        </button>
      </div>

      {isLoading && notifications.length === 0 ? (
        <div className="text-sm text-neutral-400">{t('common:loadingEllipsis')}</div>
      ) : notifications.length === 0 ? (
        <div className="flex items-center gap-2 text-sm text-neutral-400">
          <BellOff size={16} />
          {t('notifications:list.empty')}
        </div>
      ) : isManageScope ? (
        <ManageList notifications={notifications} deletingId={deletingId} onDelete={handleDelete} />
      ) : (
        <div className="flex flex-col gap-3">
          {notifications.map((notification) => (
            <NotificationCard key={notification.id} notification={notification} />
          ))}
        </div>
      )}
    </section>
  );
}

interface ManageListProps {
  notifications: Notification[];
  deletingId: string | null;
  onDelete: (notification: Notification) => void;
}

// Separate component so residency names are only fetched for managers.
function ManageList({ notifications, deletingId, onDelete }: ManageListProps) {
  const { groups } = useResidencies();

  const residencyNames = useMemo(
    () =>
      new Map(
        groups.flatMap((group) =>
          group.residencies.map((residency) => [residency.id, residency.name] as const),
        ),
      ),
    [groups],
  );

  return (
    <div className="flex flex-col gap-3">
      {notifications.map((notification) => (
        <NotificationCard
          key={notification.id}
          notification={notification}
          residencyNames={residencyNames}
          onDelete={onDelete}
          isDeleting={deletingId === notification.id}
        />
      ))}
    </div>
  );
}
