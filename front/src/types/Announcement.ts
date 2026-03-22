export interface AnnouncementTag {
  label: string;
  color: string;
}

export interface Announcement {
  title: string;
  content: string;
  tags: AnnouncementTag[];
  date: Date;
}
