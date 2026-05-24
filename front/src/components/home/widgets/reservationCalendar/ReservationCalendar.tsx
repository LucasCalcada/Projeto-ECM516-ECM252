import { useMemo, useState } from 'react';
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

function formatDisplayDate(dateStr: string): string {
  const date = new Date(`${dateStr}T00:00:00`);
  return date.toLocaleDateString('pt-BR', {
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

  const monthNames = [
    'Janeiro',
    'Fevereiro',
    'Marco',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  const daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate();
  const firstDayOfMonth = new Date(currentYear, currentMonth, 1).getDay();

  const days: (number | null)[] = [];
  for (let i = 0; i < firstDayOfMonth; i++) {
    days.push(null);
  }
  for (let i = 1; i <= daysInMonth; i++) {
    days.push(i);
  }

  const weekDays = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
  const selectedReservations = selectedDate ? reservationsByDate.get(selectedDate) : undefined;

  return (
    <div className="reservation-calendar">
      <div className="calendar-header">
        <button
          type="button"
          onClick={handlePrevMonth}
          className="nav-button"
          aria-label="Mes anterior"
        >
          {'<'}
        </button>
        <h3 className="month-year">
          {monthNames[currentMonth]} de {currentYear}
        </h3>
        <button
          type="button"
          onClick={handleNextMonth}
          className="nav-button"
          aria-label="Proximo mes"
        >
          {'>'}
        </button>
      </div>

      <div className="weekdays">
        {weekDays.map((day, index) => (
          <div key={`${day}-${index}`} className="weekday">
            {day}
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
                  ? 'Data passada'
                  : status === 'reserved'
                    ? 'Dia reservado'
                    : 'Disponivel'
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
          <h4 className="reservations-title">Reservas para {formatDisplayDate(selectedDate)}</h4>
          <div className="alert-message">Este dia ja foi reservado.</div>
        </div>
      ) : null}
    </div>
  );
}
