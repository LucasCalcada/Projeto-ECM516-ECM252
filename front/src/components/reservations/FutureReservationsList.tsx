import { useEffect, useMemo, useState } from 'react';
import {
  mapReservationApiResponse,
  type Reservation,
  type ReservationApiResponse,
} from '../../types/Reservation';
import useService from '../../helpers/useService';

function formatReservationDate(date: string): string {
  return new Date(`${date}T00:00:00`).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
}

function getTimeUntilReservation(dateStr: string): string {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const targetDate = new Date(`${dateStr}T00:00:00`);
  targetDate.setHours(0, 0, 0, 0);

  const diffTime = targetDate.getTime() - today.getTime();
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  if (diffDays < 0) return 'Passada';
  if (diffDays === 0) return 'Hoje';
  if (diffDays === 1) return 'Amanha';
  if (diffDays < 7) return `Em ${diffDays} dias`;
  if (diffDays < 30) {
    const weeks = Math.floor(diffDays / 7);
    return `Em ${weeks} semana${weeks > 1 ? 's' : ''}`;
  }

  const months = Math.floor(diffDays / 30);
  return `Em ${months} mes${months > 1 ? 'es' : ''}`;
}

export default function FutureReservationsList() {
  const reservationService = useService('reservation');
  const [myReservations, setMyReservations] = useState<Reservation[]>([]);
  const [isMyReservationsLoading, setIsMyReservationsLoading] = useState(false);
  const [myReservationsFeedback, setMyReservationsFeedback] = useState<string>('');

  const upcomingMyReservations = useMemo(() => {
    return [...myReservations].sort((a, b) => {
      return new Date(`${a.date}T00:00:00`).getTime() - new Date(`${b.date}T00:00:00`).getTime();
    });
  }, [myReservations]);

  useEffect(() => {
    async function fetchMyReservations() {
      try {
        setIsMyReservationsLoading(true);
        setMyReservationsFeedback('');

        const response = await reservationService.get<ReservationApiResponse[]>(
          '/reservations/my-apartment',
        );
        setMyReservations(response.data.map(mapReservationApiResponse));
      } catch (error) {
        console.error('Erro ao buscar reservas do apartamento:', error);
        setMyReservationsFeedback('Não foi possível carregar suas futuras reservas.');
      } finally {
        setIsMyReservationsLoading(false);
      }
    }

    fetchMyReservations();
  }, [reservationService]);

  return (
    <section className="flex min-h-0 flex-col overflow-hidden rounded-xl border border-neutral-800 bg-neutral-900/40 p-3">
      <div className="mb-3 flex shrink-0 flex-wrap items-center justify-between gap-2">
        <h2 className="text-lg font-semibold">Minhas futuras reservas</h2>
        {isMyReservationsLoading ? (
          <span className="rounded-full border border-neutral-700 px-2 py-0.5 text-xs text-neutral-300">
            Carregando
          </span>
        ) : null}
      </div>

      <div className="min-h-0 flex-1 space-y-3 overflow-y-auto pr-1">
        {myReservationsFeedback ? (
          <p className="rounded-md border border-red-900/50 bg-red-950/30 p-3 text-sm text-red-200">
            {myReservationsFeedback}
          </p>
        ) : null}

        {!myReservationsFeedback &&
        !isMyReservationsLoading &&
        upcomingMyReservations.length === 0 ? (
          <p className="text-sm text-neutral-400">
            Seu apartamento ainda nao possui reservas futuras.
          </p>
        ) : null}

        {upcomingMyReservations.map((reservation) => (
          <article
            key={reservation.id}
            className="rounded-lg border border-neutral-800 bg-neutral-950 p-3"
          >
            <div className="flex flex-wrap items-center justify-between gap-2">
              <p className="font-medium text-neutral-100">{reservation.commonAreaName}</p>
              <span className="rounded-full border border-neutral-700 px-2 py-0.5 text-xs text-neutral-300">
                Dia inteiro
              </span>
            </div>
            <p className="text-sm text-neutral-300">{formatReservationDate(reservation.date)}</p>
            <p className="mt-1 text-xs text-neutral-500">
              {getTimeUntilReservation(reservation.date)}
            </p>
          </article>
        ))}
      </div>
    </section>
  );
}
