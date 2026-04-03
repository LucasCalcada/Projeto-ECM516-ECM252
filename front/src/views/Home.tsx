import CalendarWidget from '../components/home/widgets/calendar';
import AnnouncementWidget from '../components/home/widgets/announcements';
import calendarEvents from '../mockedData/calendar';
import announcements from '../mockedData/announcements';

function Home() {
  return (
    <div className="flex items-center h-8/12 p-12 gap-4">
      <AnnouncementWidget announcements={announcements} />
      <CalendarWidget events={calendarEvents} />
    </div>
  );
}

export default Home;
