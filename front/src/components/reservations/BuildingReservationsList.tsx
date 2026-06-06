import { useEffect, useMemo, useState } from 'react';
import type { ReservationApiResponse } from '../../types/Reservation';
import useService from '../../helpers/useService';
import { useTranslation } from 'react-i18next';
import useCommonAreas from '../../helpers/useCommonAreas';

function formatReservationDate(date: string, locale: string): string {
  return new Date(`${date}T00:00:00`).toLocaleDateString(locale, {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
}

export default function BuildingReservationsList() {
  const { i18n, t } = useTranslation();
  const reservationService = useService('reservation');
  const {
    commonAreas,
    isLoading: isCommonAreasLoading,
    error: commonAreasError,
  } = useCommonAreas();
  const locale = i18n.resolvedLanguage || i18n.language;
  const [commonAreaId, setCommonAreaId] = useState('');
  const [reservations, setReservations] = useState<ReservationApiResponse[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [feedback, setFeedback] = useState('');

  const selectedArea = useMemo(
    () => commonAreas.find((area) => area.id === commonAreaId),
    [commonAreas, commonAreaId],
  );

  useEffect(() => {
    if (commonAreas.length === 0) return;
    if (commonAreas.some((area) => area.id === commonAreaId)) return;

    setCommonAreaId(commonAreas[0].id);
  }, [commonAreas, commonAreaId]);

  useEffect(() => {
    async function fetchReservations() {
      if (!commonAreaId) {
        setReservations([]);
        return;
      }

      try {
        setIsLoading(true);
        setFeedback('');

        const response = await reservationService.get<ReservationApiResponse[]>('/reservations', {
          params: {
            commonAreaId,
          },
        });

        setReservations(response.data);
      } catch (error) {
        console.error('Erro ao buscar reservas do prédio:', error);
        setFeedback(t('reservations:lists.loadBuildingError'));
      } finally {
        setIsLoading(false);
      }
    }

    fetchReservations();
  }, [commonAreaId, reservationService, t]);

  useEffect(() => {
    if (commonAreasError) {
      setFeedback(t('reservations:lists.loadBuildingError'));
    }
  }, [commonAreasError, t]);

  const selectedAreaName = selectedArea
    ? t(`reservations:commonAreas.${selectedArea.id}`, { defaultValue: selectedArea.name })
    : '';

  return (
    <section className="flex min-h-0 flex-1 flex-col overflow-hidden rounded-xl border border-neutral-800 bg-neutral-900/40 p-3">
      <div className="mb-4 flex shrink-0 flex-wrap items-end justify-between gap-3">
        <label className="block w-full max-w-sm">
          <span className="mb-1 block text-sm text-neutral-300">{t('common:commonArea')}</span>
          <select
            className="h-10 w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
            value={commonAreaId}
            onChange={(event) => setCommonAreaId(event.target.value)}
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

        {isLoading || isCommonAreasLoading ? (
          <span className="rounded-full border border-neutral-700 px-2 py-0.5 text-xs text-neutral-300">
            {t('common:loading')}
          </span>
        ) : null}
      </div>

      <div className="min-h-0 flex-1 space-y-3 overflow-y-auto pr-1">
        {feedback ? (
          <p className="rounded-md border border-red-900/50 bg-red-950/30 p-3 text-sm text-red-200">
            {feedback}
          </p>
        ) : null}

        {!feedback && !isLoading && reservations.length === 0 ? (
          <p className="text-sm text-neutral-400">
            {t('reservations:lists.emptyBuilding', { areaName: selectedAreaName })}
          </p>
        ) : null}

        {reservations.map((reservation) => (
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
              {formatReservationDate(reservation.reservationDate, locale)}
            </p>
            <p className="mt-1 text-xs text-neutral-500">{reservation.residentName}</p>
          </article>
        ))}
      </div>
    </section>
  );
}
