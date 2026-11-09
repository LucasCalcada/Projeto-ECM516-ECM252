import { Building2, CalendarClock, Home, Trash2 } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import type Notification from '../../types/Notification';

interface NotificationCardProps {
  notification: Notification;
  // Resolves residency ids to display names; when absent, a generic label is shown.
  residencyNames?: Map<string, string>;
  onDelete?: (notification: Notification) => void;
  isDeleting?: boolean;
}

function AudienceBadge({
  residencyIds,
  residencyNames,
}: {
  residencyIds: string[];
  residencyNames?: Map<string, string>;
}) {
  const { t } = useTranslation();
  const isBuildingWide = residencyIds.length === 0;
  const Icon = isBuildingWide ? Building2 : Home;

  let label: string;
  if (isBuildingWide) {
    label = t('notifications:audience.building');
  } else if (residencyNames) {
    label = residencyIds
      .map((id) => residencyNames.get(id) ?? t('notifications:audience.unknownResidency'))
      .join(', ');
  } else {
    label = t('notifications:audience.myResidency');
  }

  return (
    <span className="inline-flex max-w-full items-center gap-1 rounded-md border border-neutral-700 bg-neutral-950 px-2 py-1 text-xs font-semibold text-neutral-100">
      <Icon size={12} className="shrink-0" />
      <span className="truncate">{label}</span>
    </span>
  );
}

export default function NotificationCard({
  notification,
  residencyNames,
  onDelete,
  isDeleting,
}: NotificationCardProps) {
  const { i18n, t } = useTranslation();
  const locale = i18n.resolvedLanguage || i18n.language;

  return (
    <article className="flex flex-col gap-2 rounded-lg border border-neutral-800 bg-neutral-950/60 p-4">
      <div className="flex items-start justify-between gap-3">
        <h2 className="min-w-0 text-lg font-bold break-words text-neutral-100">
          {notification.title}
        </h2>
        {onDelete && (
          <button
            type="button"
            className="inline-flex shrink-0 items-center gap-2 rounded-md border border-red-500/40 px-3 py-1.5 text-sm font-semibold text-red-300 transition hover:bg-red-500/10 disabled:cursor-not-allowed disabled:opacity-60"
            onClick={() => onDelete(notification)}
            disabled={isDeleting}
          >
            <Trash2 size={14} />
            {isDeleting ? t('notifications:list.deleting') : t('notifications:list.delete')}
          </button>
        )}
      </div>

      <div className="flex flex-wrap items-center gap-2">
        <AudienceBadge residencyIds={notification.residencyIds} residencyNames={residencyNames} />
        {notification.eventAt && (
          <span className="inline-flex items-center gap-1 rounded-md bg-cyan-300/10 px-2 py-1 text-xs font-semibold text-cyan-200">
            <CalendarClock size={12} />
            {new Date(notification.eventAt).toLocaleString(locale)}
          </span>
        )}
      </div>

      <p className="text-sm whitespace-pre-line text-neutral-300">{notification.description}</p>

      <p className="text-xs text-neutral-500">
        {t('notifications:list.createdAt', {
          date: new Date(notification.createdAt).toLocaleString(locale),
        })}
      </p>
    </article>
  );
}
