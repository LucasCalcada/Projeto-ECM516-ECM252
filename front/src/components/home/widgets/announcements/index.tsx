import { Megaphone } from 'lucide-react';
import type { Announcement, AnnouncementTag } from '../../../../types/Announcement';
import { useTranslation } from 'react-i18next';

function AnnouncementTagEntry(props: { tag: AnnouncementTag }) {
  return (
    <p className="rounded-md border-neutral-700 bg-neutral-800 p-1 px-2 text-xs">
      {props.tag.label}
    </p>
  );
}

function AnnouncementEntry(props: { announcement: Announcement }) {
  return (
    <div className="border-l-2 border-neutral-800 pl-4">
      <p className="truncate text-xl font-bold">{props.announcement.title}</p>
      <div className="flex flex-wrap gap-1">
        {props.announcement.tags.map((t) => (
          <AnnouncementTagEntry tag={t} />
        ))}
      </div>
      <p className="line-clamp-2 text-ellipsis text-neutral-500">{props.announcement.content}</p>
    </div>
  );
}

export default function AnnouncementWidget(props: { announcements: Announcement[] }) {
  const { t } = useTranslation();
  return (
    <div className="flex-2 self-stretch rounded-xl border-1 border-neutral-800 p-4">
      <div className="flex items-center gap-2">
        <Megaphone />
        <p className="text-2xl font-bold">{t('announcements:title')}</p>
      </div>
      <div className="grid grid-cols-2 gap-4 overflow-y-scroll pt-2">
        {props.announcements.map((a) => (
          <AnnouncementEntry announcement={a} />
        ))}
      </div>
    </div>
  );
}
