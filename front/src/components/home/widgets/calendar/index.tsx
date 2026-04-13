import { Calendar } from 'lucide-react';
import type { CalendarEvent } from '../../../../types/CalendarEvent';
import CalendarDate from './calendarEventDate';
import { useTranslation } from 'react-i18next';

function CalendarEventEntry(props: { event: CalendarEvent }) {
  return (
    <div className="flex gap-2 border-neutral-900 py-2 not-last:border-b-1">
      <CalendarDate date={props.event.date} />
      <div>
        <p className="text-xl font-bold">{props.event.title}</p>
        <p className="text text-neutral-500">{props.event.description}</p>
      </div>
    </div>
  );
}

export default function CalendarWidget(props: { events: CalendarEvent[] }) {
  const { t } = useTranslation();

  return (
    <div className="flex-1 self-stretch rounded-xl border-1 border-neutral-800 p-4">
      <div className="flex items-center gap-2">
        <Calendar />
        <p className="text-2xl font-bold">{t('apps.calendar.title')}</p>
      </div>
      <div className="flex flex-col overflow-y-scroll pt-2">
        {props.events.map((e) => (
          <CalendarEventEntry event={e} />
        ))}
      </div>
    </div>
  );
}
