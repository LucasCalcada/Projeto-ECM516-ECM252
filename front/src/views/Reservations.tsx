import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import FutureReservationsList from '../components/reservations/FutureReservationsList';
import ReservationCalendarPanel from '../components/reservations/ReservationCalendarPanel';
import type { Reservation } from '../types/Reservation';

export default function Reservations() {
  const { t } = useTranslation();
  const [createdReservation, setCreatedReservation] = useState<Reservation | null>(null);

  return (
    <div className="flex h-[calc(100vh-1rem)] max-h-[calc(100vh-1rem)] min-h-0 w-full flex-col overflow-hidden p-3 md:p-4">
      <div className="mb-3 shrink-0">
        <h1 className="text-2xl font-bold text-neutral-100">{t('reservations:title')}</h1>
        <p className="text-neutral-400">{t('reservations:description')}</p>
      </div>

      <div className="grid min-h-0 flex-1 grid-cols-1 gap-3 lg:grid-cols-[minmax(0,1.15fr)_minmax(320px,0.85fr)]">
        <ReservationCalendarPanel onReservationCreated={setCreatedReservation} />
        <FutureReservationsList createdReservation={createdReservation} />
      </div>
    </div>
  );
}
