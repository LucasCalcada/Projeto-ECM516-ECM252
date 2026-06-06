import { type FormEvent, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  mapReservationApiResponse,
  type Reservation,
  type ReservationApiResponse,
} from '../../types/Reservation';
import { ReservationCalendar } from '../home/widgets/reservationCalendar';
import useService from '../../helpers/useService';
import { useToast } from '../Toast';
import useCommonAreas from '../../helpers/useCommonAreas';

interface NewReservationForm {
  commonAreaId: string;
  date: string;
}

function getHttpStatus(error: unknown) {
  if (typeof error !== 'object' || error === null || !('response' in error)) {
    return undefined;
  }

  const response = (error as { response?: { status?: number } }).response;
  return response?.status;
}

function formatReservationDate(date: string, locale: string): string {
  return new Date(`${date}T00:00:00`).toLocaleDateString(locale, {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
}

export default function ReservationCalendarPanel() {
  const { i18n, t } = useTranslation();
  const reservationService = useService('reservation');
  const { commonAreas, isLoading: isCommonAreasLoading } = useCommonAreas();
  const locale = i18n.resolvedLanguage || i18n.language;

  const [calendarReservations, setCalendarReservations] = useState<Reservation[]>([]);
  const [isCalendarLoading, setIsCalendarLoading] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [feedback, setFeedback] = useState<string>('');
  const { notifySuccess } = useToast();
  const [form, setForm] = useState<NewReservationForm>({
    commonAreaId: '',
    date: '',
  });

  const selectedArea = commonAreas.find((area) => area.id === form.commonAreaId);
  const selectedAreaName = selectedArea
    ? t(`reservations:commonAreas.${selectedArea.id}`, { defaultValue: selectedArea.name })
    : '';

  useEffect(() => {
    if (commonAreas.length === 0) return;
    if (commonAreas.some((area) => area.id === form.commonAreaId)) return;

    setForm({ commonAreaId: commonAreas[0].id, date: '' });
  }, [commonAreas, form.commonAreaId]);

  useEffect(() => {
    async function fetchReservations() {
      if (!form.commonAreaId) {
        setCalendarReservations([]);
        return;
      }

      try {
        setIsCalendarLoading(true);
        setFeedback('');

        const response = await reservationService.get<ReservationApiResponse[]>('/reservations', {
          params: {
            commonAreaId: form.commonAreaId,
          },
        });

        setCalendarReservations(response.data.map(mapReservationApiResponse));
      } catch (error) {
        console.error('Erro ao buscar reservas:', error);
      } finally {
        setIsCalendarLoading(false);
      }
    }

    fetchReservations();
  }, [form.commonAreaId, reservationService]);

  function onCommonAreaChange(commonAreaId: string) {
    setForm({ commonAreaId, date: '' });
  }

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!selectedArea || !form.date) {
      setFeedback(t('reservations:form.feedback.missingFields'));
      return;
    }

    try {
      setIsSubmitting(true);
      setFeedback('');

      const response = await reservationService.post<ReservationApiResponse>('/reservations', {
        commonAreaId: selectedArea.id,
        commonAreaName: selectedArea.name,
        reservationDate: form.date,
      });

      const reservation = mapReservationApiResponse(response.data);
      setCalendarReservations((prev) => [...prev, reservation]);
      notifySuccess(
        t('reservations:form.toast.successTitle'),
        t('reservations:form.toast.successMessage'),
      );
      setForm((prev) => ({ ...prev, date: '' }));
    } catch (error) {
      if (getHttpStatus(error) === 409) {
        setFeedback(t('reservations:form.feedback.conflict'));
        return;
      }

      console.error('Erro ao criar reserva:', error);
      setFeedback(t('reservations:form.feedback.createError'));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <section className="flex min-h-0 flex-col overflow-hidden rounded-xl border border-neutral-800 bg-neutral-900/40 p-3">
      <div className="mb-3 shrink-0">
        <h2 className="mb-2 text-base font-semibold">{t('reservations:form.title')}</h2>
        <form className="grid gap-2" onSubmit={onSubmit}>
          <div className="flex flex-col gap-2">
            <label className="block">
              <select
                className="h-10 w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={form.commonAreaId}
                onChange={(event) => onCommonAreaChange(event.target.value)}
                disabled={isCommonAreasLoading || commonAreas.length === 0}
              >
                {commonAreas.map((area) => (
                  <option key={area.id} value={area.id}>
                    {t(`reservations:commonAreas.${area.id}`, { defaultValue: area.name })} (
                    {t('reservations:form.people', { count: area.limit })})
                  </option>
                ))}
              </select>
            </label>

            {selectedArea ? (
              <div className="rounded-md border border-neutral-800 bg-neutral-950 px-3 py-2 text-sm text-neutral-300">
                <p className={form.date ? 'text-neutral-100' : 'text-neutral-500'}>
                  {form.date
                    ? formatReservationDate(form.date, locale)
                    : t('reservations:form.selectDate')}
                </p>
              </div>
            ) : null}
          </div>

          <div className="justify-begin flex">
            <button
              type="submit"
              disabled={isSubmitting || isCommonAreasLoading || !selectedArea}
              className="h-10 w-full rounded-md bg-neutral-100 px-4 text-sm font-medium text-neutral-900 transition hover:bg-white disabled:cursor-not-allowed disabled:opacity-60 md:w-auto"
            >
              {isSubmitting ? t('reservations:form.submitting') : t('reservations:form.confirm')}
            </button>
          </div>
        </form>

        {feedback ? <p className="mt-3 text-sm text-neutral-300">{feedback}</p> : null}
      </div>

      <div className="mb-2 flex shrink-0 flex-wrap items-start justify-between gap-2">
        <div>
          <h2 className="text-base font-semibold">{t('reservations:calendar.title')}</h2>
          <p className="text-xs text-neutral-400">
            {t('reservations:calendar.description', { areaName: selectedAreaName })}
          </p>
        </div>
        {isCalendarLoading ? (
          <span className="rounded-full border border-neutral-700 px-2 py-0.5 text-xs text-neutral-300">
            {t('common:loading')}
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
    </section>
  );
}
