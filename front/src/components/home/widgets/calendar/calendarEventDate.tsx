const months = [
  "JAN",
  "FEB",
  "MAR",
  "APR",
  "MAY",
  "JUN",
  "JUL",
  "AUG",
  "SEP",
  "OCT",
  "NOV",
  "DEC",
];

export default function CalendarDate(props: { date: Date }) {
  const monthLabel = months[props.date.getMonth()];
  const dateLabel = String(props.date.getDate()).padStart(2, "0");
  return (
    <div className="flex flex-col justify-center font-bold text-center aspect-square">
      <p className="text-neutral-500">{monthLabel}</p>
      <p className="text-2xl">{dateLabel}</p>
    </div>
  );
}
