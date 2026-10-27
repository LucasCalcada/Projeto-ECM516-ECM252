import { useEffect, useMemo, useState } from 'react';
import {
  mapReservationApiResponse,
  type Reservation,
  type ReservationApiResponse,
} from '../../types/Reservation';
import useService from '../../helpers/useService';
import { useTranslation } from 'react-i18next';
import type { TFunction } from 'i18next';

function formatReservationDate(date: string, locale: string): string {
  return new Date(`${date}T00:00:00`).toLocaleDateString(locale, {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
}

function getTimeUntilReservation(dateStr: string, t: TFunction): string {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const targetDate = new Date(`${dateStr}T00:00:00`);
  targetDate.setHours(0, 0, 0, 0);

  const diffTime = targetDate.getTime() - today.getTime();
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  if (diffDays < 0) return t('reservations:relative.past');
  if (diffDays === 0) return t('reservations:relative.today');
  if (diffDays === 1) return t('reservations:relative.tomorrow');
  if (diffDays < 7) return t('reservations:relative.days', { count: diffDays });
  if (diffDays < 30) {
    const weeks = Math.floor(diffDays / 7);
    return t('reservations:relative.weeks', { count: weeks });
  }

  const months = Math.floor(diffDays / 30);
  return t('reservations:relative.months', { count: months });
}

export default function FutureReservationsList() {
  const { i18n, t } = useTranslation();
  const reservationService = useService('reservation');
  const locale = i18n.resolvedLanguage || i18n.language;
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
        setMyReservationsFeedback(t('reservations:lists.loadFutureError'));
      } finally {
        setIsMyReservationsLoading(false);
      }
    }

    fetchMyReservations();
  }, [reservationService, t]);

  return (
    <section className="flex h-full flex-col overflow-hidden rounded-xl border border-neutral-800 bg-neutral-900/40 p-3">
      <div className="mb-3 flex shrink-0 flex-wrap items-center justify-between gap-2">
        <h2 className="text-lg font-semibold">{t('reservations:lists.futureTitle')}</h2>
        {isMyReservationsLoading ? (
          <span className="rounded-full border border-neutral-700 px-2 py-0.5 text-xs text-neutral-300">
            {t('common:loading')}
          </span>
        ) : null}
      </div>

      <div className="flex h-full flex-col gap-2 space-y-3 overflow-y-auto pr-1">
        {myReservationsFeedback ? (
          <p className="rounded-md border border-red-900/50 bg-red-950/30 p-3 text-sm text-red-200">
            {myReservationsFeedback}
          </p>
        ) : null}

        {!myReservationsFeedback &&
        !isMyReservationsLoading &&
        upcomingMyReservations.length === 0 ? (
          <p className="text-sm text-neutral-400">{t('reservations:lists.emptyFuture')}</p>
        ) : null}

        {upcomingMyReservations.map((reservation) => (
          <article
            key={reservation.id}
            className="rounded-lg border border-neutral-800 bg-neutral-950 p-3"
          >
            <div className="flex flex-wrap items-center justify-between gap-2">
              <p className="font-medium text-neutral-100">{reservation.commonAreaName}</p>
              <span className="rounded-full border border-neutral-700 px-2 py-0.5 text-xs text-neutral-300">
                {t('common:allDay')}
              </span>
            </div>
            <p className="text-sm text-neutral-300">
              {formatReservationDate(reservation.date, locale)}
            </p>
            <p className="mt-1 text-xs text-neutral-500">
              {getTimeUntilReservation(reservation.date, t)}
            </p>
          </article>
        ))}
      </div>
    </section>
  );
}
