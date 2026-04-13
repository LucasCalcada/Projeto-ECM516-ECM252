import { type FormEvent, useMemo, useState } from 'react';
import commonAreas from '../mockedData/commonAreas';
import initialReservations from '../mockedData/reservations';
import type { Reservation } from '../types/Reservation';
import { useTranslation } from 'react-i18next';
import { ReservationCalendar } from '../components/home/widgets/reservationCalendar';
import { BuildingRulesNotification } from '../components/home/widgets/buildingRulesNotification';

interface NewReservationForm {
  residentName: string;
  commonAreaId: string;
  date: string;
  startTime: string;
  endTime: string;
  notes: string;
}

function formatDate(date: string): string {
  return new Date(`${date}T00:00:00`).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
}

function getTimeUntil(dateStr: string): string {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const targetDate = new Date(dateStr);
  targetDate.setHours(0, 0, 0, 0);

  const diffTime = targetDate.getTime() - today.getTime();
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  if (diffDays < 0) return 'Passada';
  if (diffDays === 0) return 'Hoje';
  if (diffDays === 1) return 'Amanhã';
  if (diffDays < 7) return `Em ${diffDays} dias`;
  if (diffDays < 30) {
    const weeks = Math.floor(diffDays / 7);
    return `Em ${weeks} semana${weeks > 1 ? 's' : ''}`;
  }

  const months = Math.floor(diffDays / 30);
  return `Em ${months} mês${months > 1 ? 'es' : ''}`;
}

export default function Reservations() {
  const { t } = useTranslation();

  const [reservations, setReservations] = useState<Reservation[]>(initialReservations);
  const [feedback, setFeedback] = useState<string>('');
  const [showRulesModal, setShowRulesModal] = useState(false);
  const [lastReservation, setLastReservation] = useState<{
    residentName: string;
    commonAreaName: string;
    reservationDate: string;
  } | null>(null);
  const [form, setForm] = useState<NewReservationForm>({
    residentName: '',
    commonAreaId: commonAreas[0]?.id ?? '',
    date: '',
    startTime: '',
    endTime: '',
    notes: '',
  });

  const upcomingReservations = useMemo(() => {
    return [...reservations].sort((a, b) => {
      return new Date(a.date).getTime() - new Date(b.date).getTime();
    });
  }, [reservations]);

  const selectedArea = commonAreas.find((area) => area.id === form.commonAreaId);

  function onInputChange<K extends keyof NewReservationForm>(key: K, value: NewReservationForm[K]) {
    setForm((prev) => ({ ...prev, [key]: value }));
  }

  function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!form.residentName || !form.date) {
      setFeedback('Preencha todos os campos obrigatorios.');
      return;
    }

    // Verificar se o dia já foi reservado por outro morador
    const dayReservations = reservations.filter(
      (r) =>
        r.commonAreaId === form.commonAreaId && r.date === form.date && r.status !== 'cancelled',
    );

    if (dayReservations.length > 0) {
      const existingReservation = dayReservations[0];
      const isUserReservation =
        existingReservation.residentName.toLowerCase() === form.residentName.toLowerCase();

      if (!isUserReservation) {
        setFeedback(
          `Este dia ja foi reservado por ${existingReservation.residentName}. Escolha outro dia.`,
        );
        return;
      }
    }

    const area = commonAreas.find((item) => item.id === form.commonAreaId);
    if (!area) {
      setFeedback('Area comum invalida.');
      return;
    }

    const newReservation: Reservation = {
      id: `res-${reservations.length + 1}`,
      residentName: form.residentName.trim(),
      commonAreaId: area.id,
      commonAreaName: area.name,
      date: form.date,
      startTime: '00:00',
      endTime: '23:59',
      notes: form.notes.trim() || undefined,
      status: 'confirmed',
    };

    setReservations((prev) => [...prev, newReservation]);
    setLastReservation({
      residentName: newReservation.residentName,
      commonAreaName: newReservation.commonAreaName,
      reservationDate: newReservation.date,
    });
    setShowRulesModal(true);
    setFeedback('');
    setForm((prev) => ({
      ...prev,
      residentName: '',
      date: '',
      startTime: '',
      endTime: '',
      notes: '',
    }));
  }

  return (
    <div className="h-full p-4 md:p-8">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-neutral-100">{t('apps.reservations.title')}</h1>
        <p className="text-neutral-400">{t('apps.reservations.description')}</p>
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-5">
        <section className="rounded-xl border border-neutral-800 bg-neutral-900/40 p-4 lg:col-span-3">
          <h2 className="mb-3 text-lg font-semibold">{t('apps.reservations.upcoming')}</h2>
          <div className="space-y-3">
            {upcomingReservations.map((reservation) => (
              <article
                key={reservation.id}
                className="rounded-lg border border-neutral-800 bg-neutral-950 p-3"
              >
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <p className="font-medium text-neutral-100">{reservation.commonAreaName}</p>
                  <span className="rounded-full border border-neutral-700 px-2 py-0.5 text-xs text-neutral-300">
                    {t(`apps.reservations.status.${reservation.status}`)}
                  </span>
                </div>
                <p className="text-sm text-neutral-300">{formatDate(reservation.date)}</p>
                <p className="text-sm text-neutral-400">{reservation.residentName}</p>
                <p className="mt-1 text-xs text-neutral-500">🔔 {getTimeUntil(reservation.date)}</p>
                {reservation.notes ? (
                  <p className="mt-1 text-sm text-neutral-500">
                    {t('apps.reservations.form.comment')}: {reservation.notes}
                  </p>
                ) : null}
              </article>
            ))}
          </div>
        </section>

        <section className="rounded-xl border border-neutral-800 bg-neutral-900/40 p-4 lg:col-span-2">
          <h2 className="mb-3 text-lg font-semibold">Nova reserva</h2>
          <form className="space-y-3" onSubmit={onSubmit}>
            <label className="block">
              <span className="mb-1 block text-sm text-neutral-300">
                {t('apps.reservations.form.resident')}
              </span>
              <input
                className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={form.residentName}
                onChange={(e) => onInputChange('residentName', e.target.value)}
                placeholder="Ex.: Joao - Apto 41"
              />
            </label>

            <label className="block">
              <span className="mb-1 block text-sm text-neutral-300">
                {t('apps.reservations.form.resource')}
              </span>
              <select
                className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={form.commonAreaId}
                onChange={(e) => onInputChange('commonAreaId', e.target.value)}
              >
                {commonAreas.map((area) => (
                  <option key={area.id} value={area.id}>
                    {area.name} ({area.capacity} pessoas)
                  </option>
                ))}
              </select>
            </label>

            {selectedArea ? (
              <p className="text-xs text-neutral-500">
                Horario de funcionamento: {selectedArea.openingHour} as {selectedArea.closingHour}
              </p>
            ) : null}

            {selectedArea ? (
              <div className="block">
                <span className="mb-1 block text-sm text-neutral-300">
                  {t('apps.reservations.form.date')}
                </span>
                <ReservationCalendar
                  reservations={reservations}
                  commonAreaId={form.commonAreaId}
                  selectedDate={form.date}
                  onDateSelect={(date) => onInputChange('date', date)}
                  currentUserName={form.residentName}
                />
              </div>
            ) : null}

            <label className="block">
              <span className="mb-1 block text-sm text-neutral-300">
                {t('apps.reservations.form.comment')}
              </span>
              <textarea
                className="min-h-20 w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={form.notes}
                onChange={(e) => onInputChange('notes', e.target.value)}
              />
            </label>

            <button
              type="submit"
              className="w-full rounded-md bg-neutral-100 px-3 py-2 text-sm font-medium text-neutral-900 transition hover:bg-white"
            >
              {t('apps.reservations.form.confirm')}
            </button>
          </form>

          {feedback ? <p className="mt-3 text-sm text-neutral-300">{feedback}</p> : null}
        </section>
      </div>

      {lastReservation && (
        <BuildingRulesNotification
          isOpen={showRulesModal}
          onClose={() => setShowRulesModal(false)}
          residentName={lastReservation.residentName}
          commonAreaName={lastReservation.commonAreaName}
          reservationDate={lastReservation.reservationDate}
        />
      )}
    </div>
  );
}
