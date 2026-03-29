import { Megaphone } from "lucide-react";
import type {
  Announcement,
  AnnouncementTag,
} from "../../../../types/Announcement";
import { useTranslation } from "react-i18next";

function AnnouncementTagEntry(props: { tag: AnnouncementTag }) {
  return (
    <p className="bg-neutral-800 text-xs p-1 px-2 rounded-md border-neutral-700">
      {props.tag.label}
    </p>
  );
}

function AnnouncementEntry(props: { announcement: Announcement }) {
  return (
    <div className="border-neutral-800 border-l-2 pl-4">
      <p className="font-bold text-xl truncate">{props.announcement.title}</p>
      <div className="flex gap-1 flex-wrap">
        {props.announcement.tags.map((t) => (
          <AnnouncementTagEntry tag={t} />
        ))}
      </div>
      <p className="text-ellipsis text-neutral-500 line-clamp-2">
        {props.announcement.content}
      </p>
    </div>
  );
}

export default function AnnouncementWidget(props: {
  announcements: Announcement[];
}) {
  const { t } = useTranslation();
  return (
    <div className="border-1 border-neutral-800 rounded-xl p-4 flex-2 self-stretch">
      <div className="flex gap-2 items-center">
        <Megaphone />
        <p className="font-bold text-2xl">{t("apps.announcements.title")}</p>
      </div>
      <div className="pt-2 overflow-y-scroll grid grid-cols-2 gap-4">
        {props.announcements.map((a) => (
          <AnnouncementEntry announcement={a} />
        ))}
      </div>
    </div>
  );
}
