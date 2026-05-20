import { useEffect, useMemo, useState } from 'react';
import CalendarWidget from '../components/home/widgets/calendar';
import AnnouncementWidget from '../components/home/widgets/announcements';
import type { Announcement } from '../types/Announcement';
import type { CalendarEvent } from '../types/CalendarEvent';
import useService from '../helpers/useService';

interface CommunicationPost {
  id: string;
  title: string;
  description: string;
  eventAt: string | null;
  createdAt: string;
}

function Home() {
  const communicationService = useService('communication');
  const [posts, setPosts] = useState<CommunicationPost[]>([]);

  useEffect(() => {
    async function loadPosts() {
      const response = await communicationService.get<CommunicationPost[]>('/posts');
      setPosts(response.data);
    }

    loadPosts();
  }, [communicationService]);

  const announcements = useMemo<Announcement[]>(
    () =>
      posts
        .filter((post) => !post.eventAt)
        .map((post) => ({
          title: post.title,
          content: post.description,
          date: new Date(post.createdAt),
          tags: [],
        })),
    [posts],
  );

  const calendarEvents = useMemo<CalendarEvent[]>(
    () =>
      posts
        .filter((post) => post.eventAt)
        .map((post) => ({
          title: post.title,
          description: post.description,
          date: new Date(post.eventAt as string),
        })),
    [posts],
  );

  return (
    <div className="flex h-8/12 items-center gap-4 p-12">
      <AnnouncementWidget announcements={announcements} />
      <CalendarWidget events={calendarEvents} />
    </div>
  );
}

export default Home;
