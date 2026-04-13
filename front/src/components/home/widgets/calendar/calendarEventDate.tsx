import { useTranslation } from 'react-i18next';

const monthKeys = [
  'jan',
  'feb',
  'mar',
  'apr',
  'may',
  'jun',
  'jul',
  'aug',
  'sep',
  'oct',
  'nov',
  'dec',
];

export default function CalendarDate(props: { date: Date }) {
  const { t } = useTranslation();

  const monthKey = monthKeys[props.date.getMonth()];
  const monthLabel = t(`calendar:months.${monthKey}`).toUpperCase();

  const dateLabel = String(props.date.getDate()).padStart(2, '0');
  return (
    <div className="flex aspect-square flex-col justify-center text-center font-bold">
      <p className="text-neutral-500">{monthLabel}</p>
      <p className="text-2xl">{dateLabel}</p>
    </div>
  );
}
