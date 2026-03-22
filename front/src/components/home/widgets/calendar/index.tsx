import { Calendar } from "lucide-react";
import type { CalendarEvent } from "../../../../types/CalendarEvent";
import CalendarDate from "./calendarEventDate";

function CalendarEventEntry(props: { event: CalendarEvent }) {
  return (
    <div className="flex gap-2 py-2 not-last:border-b-1 border-neutral-900">
      <CalendarDate date={props.event.date} />
      <div>
        <p className="font-bold text-xl">{props.event.title}</p>
        <p className="text text-neutral-500">{props.event.description}</p>
      </div>
    </div>
  );
}

export default function CalendarWidget(props: { events: CalendarEvent[] }) {
  return (
    <div className="border-1 border-neutral-800 rounded-xl p-4 flex-1 self-stretch">
      <div className="flex gap-2 items-center">
        <Calendar />
        <p className="font-bold text-2xl">Calendar</p>
      </div>
      <div className="flex flex-col overflow-y-scroll pt-2">
        {props.events.map((e) => (
          <CalendarEventEntry event={e} />
        ))}
      </div>
    </div>
  );
}
