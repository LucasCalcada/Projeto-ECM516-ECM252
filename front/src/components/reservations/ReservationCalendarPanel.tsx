import { type FormEvent, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import config from '../../config';
import commonAreas from '../../mockedData/commonAreas';
import type { Reservation } from '../../types/Reservation';
import { BuildingRulesNotification } from '../home/widgets/buildingRulesNotification';
import { ReservationCalendar } from '../home/widgets/reservationCalendar';
import {
  type ApiReservation,
  formatReservationDate,
  getAccessToken,
  mapApiReservation,
} from './reservationHelpers';

interface NewReservationForm {
  commonAreaId: string;
  date: string;
}

interface ReservationCalendarPanelProps {
  onReservationCreated: (reservation: Reservation) => void;
}

export default function ReservationCalendarPanel({
  onReservationCreated,
}: ReservationCalendarPanelProps) {
  const { t } = useTranslation();

  const [calendarReservations, setCalendarReservations] = useState<Reservation[]>([]);
  const [isCalendarLoading, setIsCalendarLoading] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [feedback, setFeedback] = useState<string>('');
  const [showRulesModal, setShowRulesModal] = useState(false);
  const [lastReservation, setLastReservation] = useState<{
    residentName: string;
    commonAreaName: string;
    reservationDate: string;
  } | null>(null);
  const [form, setForm] = useState<NewReservationForm>({
    commonAreaId: commonAreas[0]?.id ?? '',
    date: '',
  });

  const selectedArea = commonAreas.find((area) => area.id === form.commonAreaId);

  useEffect(() => {
    async function fetchReservations() {
      if (!form.commonAreaId) return;

      try {
        setIsCalendarLoading(true);
        setFeedback('');

        const response = await fetch(
          `${config.reservationUrl}/reservations?commonAreaId=${encodeURIComponent(form.commonAreaId)}`,
          {
            headers: {
              Authorization: getAccessToken(),
            },
          },
        );

        if (!response.ok) {
          throw new Error('Erro ao carregar reservas.');
        }

        const data = (await response.json()) as ApiReservation[];
        setCalendarReservations(data.map(mapApiReservation));
      } catch (error) {
        console.error('Erro ao buscar reservas:', error);
      } finally {
        setIsCalendarLoading(false);
      }
    }

    fetchReservations();
  }, [form.commonAreaId]);

  function onCommonAreaChange(commonAreaId: string) {
    setForm({ commonAreaId, date: '' });
  }

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!selectedArea || !form.date) {
      setFeedback('Selecione uma area comum e uma data disponivel.');
      return;
    }

    try {
      setIsSubmitting(true);
      setFeedback('');

      const response = await fetch(`${config.reservationUrl}/reservations`, {
        method: 'POST',
        headers: {
          Authorization: getAccessToken(),
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          commonAreaId: selectedArea.id,
          commonAreaName: selectedArea.name,
          reservationDate: form.date,
        }),
      });

      if (response.status === 409) {
        setFeedback('Este dia ja foi reservado. Escolha outra data.');
        return;
      }

      if (!response.ok) {
        throw new Error('Erro ao criar reserva.');
      }

      const reservation = mapApiReservation((await response.json()) as ApiReservation);
      setCalendarReservations((prev) => [...prev, reservation]);
      onReservationCreated(reservation);
      setLastReservation({
        residentName: reservation.residentName,
        commonAreaName: reservation.commonAreaName,
        reservationDate: reservation.date,
      });
      setShowRulesModal(true);
      setForm((prev) => ({ ...prev, date: '' }));
    } catch (error) {
      console.error('Erro ao criar reserva:', error);
      setFeedback('Nao foi possivel criar a reserva. Tente novamente mais tarde.');
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <section className="flex min-h-0 flex-col overflow-hidden rounded-xl border border-neutral-800 bg-neutral-900/40 p-3">
      <div className="mb-3 shrink-0">
        <h2 className="mb-2 text-base font-semibold">Nova reserva</h2>
        <form
          className="grid gap-2 md:grid-cols-[minmax(0,1fr)_minmax(170px,auto)_auto]"
          onSubmit={onSubmit}
        >
          <label className="block">
            <span className="mb-1 block text-sm text-neutral-300">
              {t('reservations:form.resource')}
            </span>
            <select
              className="h-10 w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
              value={form.commonAreaId}
              onChange={(event) => onCommonAreaChange(event.target.value)}
            >
              {commonAreas.map((area) => (
                <option key={area.id} value={area.id}>
                  {area.name} ({area.capacity} pessoas)
                </option>
              ))}
            </select>
          </label>

          {selectedArea ? (
            <div className="rounded-md border border-neutral-800 bg-neutral-950 px-3 py-2 text-sm text-neutral-300">
              <span className="mb-1 block text-xs text-neutral-400">
                {t('reservations:form.date')}
              </span>
              <p className={form.date ? 'text-neutral-100' : 'text-neutral-500'}>
                {form.date ? formatReservationDate(form.date) : 'Selecione no calendario'}
              </p>
            </div>
          ) : null}

          <button
            type="submit"
            disabled={isSubmitting}
            className="h-10 self-end rounded-md bg-neutral-100 px-4 text-sm font-medium text-neutral-900 transition hover:bg-white disabled:cursor-not-allowed disabled:opacity-60"
          >
            {isSubmitting ? 'Aguarde...' : t('reservations:form.confirm')}
          </button>
        </form>

        {feedback ? <p className="mt-3 text-sm text-neutral-300">{feedback}</p> : null}
      </div>

      <div className="mb-2 flex shrink-0 flex-wrap items-start justify-between gap-2">
        <div>
          <h2 className="text-base font-semibold">Calendario da area</h2>
          <p className="text-xs text-neutral-400">
            Dias marcados em vermelho ja estao reservados para {selectedArea?.name}.
          </p>
        </div>
        {isCalendarLoading ? (
          <span className="rounded-full border border-neutral-700 px-2 py-0.5 text-xs text-neutral-300">
            Carregando
          </span>
        ) : null}
      </div>

      <div className="min-h-0 flex-1 overflow-hidden">
        <ReservationCalendar
          reservations={calendarReservations}
          commonAreaId={form.commonAreaId}
          selectedDate={form.date}
          onDateSelect={(date) => setForm((prev) => ({ ...prev, date }))}
        />
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
    </section>
  );
}
