import { useMemo, useState } from 'react';
import type { Reservation } from '../../../../types/Reservation';
import './styles.css';

interface ReservationCalendarProps {
  reservations: Reservation[];
  commonAreaId: string;
  selectedDate: string;
  onDateSelect: (date: string) => void;
  currentUserName: string;
}

export function ReservationCalendar({
  reservations,
  commonAreaId,
  selectedDate,
  onDateSelect,
  currentUserName,
}: ReservationCalendarProps) {
  const today = new Date();
  const [currentMonth, setCurrentMonth] = useState(today.getMonth());
  const [currentYear, setCurrentYear] = useState(today.getFullYear());

  // Filtrar reservas para a área comum selecionada
  const areaReservations = useMemo(() => {
    return reservations.filter((r) => r.commonAreaId === commonAreaId && r.status !== 'cancelled');
  }, [reservations, commonAreaId]);

  // Agrupar reservas por data
  const reservationsByDate = useMemo(() => {
    const map = new Map<string, Reservation[]>();
    areaReservations.forEach((r) => {
      const date = r.date;
      if (!map.has(date)) {
        map.set(date, []);
      }
      map.get(date)?.push(r);
    });
    return map;
  }, [areaReservations]);

  // Obter status do dia
  function getDayStatus(day: number): 'available' | 'reserved' | 'user-reserved' {
    const dateStr = formatDateToYYYYMMDD(new Date(currentYear, currentMonth, day));
    const dayReservations = reservationsByDate.get(dateStr);

    if (!dayReservations || dayReservations.length === 0) {
      return 'available';
    }

    // Validar se o nome do usuário é válido (não vazio e não placeholder)
    if (!currentUserName || currentUserName.trim().length === 0) {
      return 'reserved';
    }

    const hasUserReservation = dayReservations.some(
      (r) => r.residentName.toLowerCase() === currentUserName.toLowerCase(),
    );

    return hasUserReservation ? 'user-reserved' : 'reserved';
  }

  function formatDateToYYYYMMDD(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  function handlePrevMonth() {
    if (currentMonth === 0) {
      setCurrentMonth(11);
      setCurrentYear(currentYear - 1);
    } else {
      setCurrentMonth(currentMonth - 1);
    }
  }

  function handleNextMonth() {
    if (currentMonth === 11) {
      setCurrentMonth(0);
      setCurrentYear(currentYear + 1);
    } else {
      setCurrentMonth(currentMonth + 1);
    }
  }

  const monthNames = [
    'Janeiro',
    'Fevereiro',
    'Março',
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

  return (
    <div className="reservation-calendar">
      <div className="calendar-header">
        <button type="button" onClick={handlePrevMonth} className="nav-button">
          ◀
        </button>
        <h3 className="month-year">
          {monthNames[currentMonth]} de {currentYear}
        </h3>
        <button type="button" onClick={handleNextMonth} className="nav-button">
          ▶
        </button>
      </div>

      <div className="weekdays">
        {weekDays.map((day) => (
          <div key={day} className="weekday">
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
          const dayReservations = reservationsByDate.get(dateStr) || [];
          const canClickReserved = status === 'user-reserved';
          const canClick = status === 'available' || canClickReserved;

          return (
            <button
              key={day}
              type="button"
              disabled={!canClick}
              className={`day ${status} ${isSelected ? 'selected' : ''} ${!canClick ? 'disabled' : ''}`}
              onClick={() => canClick && onDateSelect(dateStr)}
              title={
                status === 'reserved' && !canClickReserved
                  ? 'Dia indisponível (já reservado)'
                  : dayReservations.length > 0
                    ? `${dayReservations.length} reserva(s)`
                    : 'Disponível'
              }
            >
              <span className="day-number">{day}</span>
              {dayReservations.length > 0 && <span className="reservation-indicator">●</span>}
            </button>
          );
        })}
      </div>

      {/* Mostrar reservas do dia selecionado */}
      {selectedDate &&
        reservationsByDate.get(selectedDate) &&
        reservationsByDate.get(selectedDate)!.length > 0 && (
          <div className="day-reservations">
            <h4 className="reservations-title">Reservas para {formatDisplayDate(selectedDate)}</h4>
            <div className="alert-message">
              ⚠️ Este dia já foi reservado. Não é possível fazer nova reserva.
            </div>
            <div className="reservations-list">
              {reservationsByDate.get(selectedDate)!.map((r) => (
                <div key={r.id} className="reservation-item">
                  <p className="resident">{r.residentName}</p>
                  <p className="time">
                    {r.startTime} - {r.endTime}
                  </p>
                  {r.notes && <p className="notes">{r.notes}</p>}
                </div>
              ))}
            </div>
          </div>
        )}
    </div>
  );
}

function formatDisplayDate(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
}
