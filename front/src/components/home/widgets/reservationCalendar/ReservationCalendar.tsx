import { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import type { Reservation } from '../../../../types/Reservation';
import './styles.css';

interface ReservationCalendarProps {
  reservations: Reservation[];
  commonAreaId: string;
  selectedDate: string;
  onDateSelect: (date: string) => void;
}

function formatDateToYYYYMMDD(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function formatDisplayDate(dateStr: string, locale: string): string {
  const date = new Date(`${dateStr}T00:00:00`);
  return date.toLocaleDateString(locale, {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
}

export function ReservationCalendar({
  reservations,
  commonAreaId,
  selectedDate,
  onDateSelect,
}: ReservationCalendarProps) {
  const { i18n, t } = useTranslation();
  const locale = i18n.resolvedLanguage || i18n.language;
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const [currentMonth, setCurrentMonth] = useState(today.getMonth());
  const [currentYear, setCurrentYear] = useState(today.getFullYear());

  const areaReservations = useMemo(() => {
    return reservations.filter((r) => r.commonAreaId === commonAreaId && r.status !== 'cancelled');
  }, [reservations, commonAreaId]);

  const reservationsByDate = useMemo(() => {
    const map = new Map<string, Reservation[]>();
    areaReservations.forEach((reservation) => {
      if (!map.has(reservation.date)) {
        map.set(reservation.date, []);
      }
      map.get(reservation.date)?.push(reservation);
    });
    return map;
  }, [areaReservations]);

  function getDayStatus(day: number): 'available' | 'reserved' | 'past' {
    const dateStr = formatDateToYYYYMMDD(new Date(currentYear, currentMonth, day));
    const date = new Date(`${dateStr}T00:00:00`);

    if (date < today) {
      return 'past';
    }

    return reservationsByDate.has(dateStr) ? 'reserved' : 'available';
  }

  function handlePrevMonth() {
    if (currentMonth === 0) {
      setCurrentMonth(11);
      setCurrentYear(currentYear - 1);
      return;
    }

    setCurrentMonth(currentMonth - 1);
  }

  function handleNextMonth() {
    if (currentMonth === 11) {
      setCurrentMonth(0);
      setCurrentYear(currentYear + 1);
      return;
    }

    setCurrentMonth(currentMonth + 1);
  }

  const monthNames = t('reservations:calendar.months', { returnObjects: true }) as Record<
    number,
    string
  >;

  const daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate();
  const firstDayOfMonth = new Date(currentYear, currentMonth, 1).getDay();

  const days: (number | null)[] = [];
  for (let i = 0; i < firstDayOfMonth; i++) {
    days.push(null);
  }
  for (let i = 1; i <= daysInMonth; i++) {
    days.push(i);
  }

  const weekDays = t(`reservations:calendar.weekDays`, { returnObjects: true }) as Record<
    number,
    string
  >;
  const selectedReservations = selectedDate ? reservationsByDate.get(selectedDate) : undefined;

  return (
    <div className="reservation-calendar">
      <div className="calendar-header">
        <button
          type="button"
          onClick={handlePrevMonth}
          className="nav-button"
          aria-label={t('reservations:calendar.previousMonth')}
        >
          {'<'}
        </button>
        <h3 className="month-year">
          {t('reservations:calendar.monthYear', {
            month: monthNames[currentMonth],
            year: currentYear,
          })}
        </h3>
        <button
          type="button"
          onClick={handleNextMonth}
          className="nav-button"
          aria-label={t('reservations:calendar.nextMonth')}
        >
          {'>'}
        </button>
      </div>

      <div className="weekdays">
        {Object.values(weekDays).map((day, index) => (
          <div key={`${day}-${index}`} className="weekday">
            {day.toUpperCase()}
          </div>
        ))}
      </div>

      <div className="days-grid">
        {days.map((day, index) => {
          if (day === null) {
            return <div key={`empty-${index}`} className="day empty" />;
          }

          const dateStr = formatDateToYYYYMMDD(new Date(currentYear, currentMonth, day));
          const status = getDayStatus(day);
          const isSelected = selectedDate === dateStr;
          const canClick = status === 'available';

          return (
            <button
              key={dateStr}
              type="button"
              disabled={!canClick}
              className={`day ${status} ${isSelected ? 'selected' : ''} ${!canClick ? 'disabled' : ''}`}
              onClick={() => canClick && onDateSelect(dateStr)}
              title={
                status === 'past'
                  ? t('reservations:calendar.dayStatus.past')
                  : status === 'reserved'
                    ? t('reservations:calendar.dayStatus.reserved')
                    : t('reservations:calendar.dayStatus.available')
              }
            >
              <span className="day-number">{day}</span>
              {status === 'reserved' ? <span className="reservation-indicator">o</span> : null}
            </button>
          );
        })}
      </div>

      {selectedReservations && selectedReservations.length > 0 ? (
        <div className="day-reservations">
          <h4 className="reservations-title">
            {t('reservations:calendar.reservationsFor', {
              date: formatDisplayDate(selectedDate, locale),
            })}
          </h4>
          <div className="alert-message">{t('reservations:calendar.reservedDay')}</div>
        </div>
      ) : null}
    </div>
  );
}
