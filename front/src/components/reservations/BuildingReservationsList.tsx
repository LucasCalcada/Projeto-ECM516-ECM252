import { useEffect, useMemo, useState } from 'react';
import commonAreas from '../../mockedData/commonAreas';
import type { ReservationApiResponse } from '../../types/Reservation';
import useService from '../../helpers/useService';

function formatReservationDate(date: string): string {
  return new Date(`${date}T00:00:00`).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
}

export default function BuildingReservationsList() {
  const reservationService = useService('reservation');
  const [commonAreaId, setCommonAreaId] = useState(commonAreas[0]?.id ?? '');
  const [reservations, setReservations] = useState<ReservationApiResponse[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [feedback, setFeedback] = useState('');

  const selectedArea = useMemo(
    () => commonAreas.find((area) => area.id === commonAreaId),
    [commonAreaId],
  );

  useEffect(() => {
    async function fetchReservations() {
      if (!commonAreaId) return;

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
        console.error('Erro ao buscar reservas do predio:', error);
        setFeedback('Nao foi possivel carregar as reservas desta area comum.');
      } finally {
        setIsLoading(false);
      }
    }

    fetchReservations();
  }, [commonAreaId, reservationService]);

  return (
    <section className="flex min-h-0 flex-1 flex-col overflow-hidden rounded-xl border border-neutral-800 bg-neutral-900/40 p-3">
      <div className="mb-4 flex shrink-0 flex-wrap items-end justify-between gap-3">
        <label className="block w-full max-w-sm">
          <span className="mb-1 block text-sm text-neutral-300">Area comum</span>
          <select
            className="h-10 w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
            value={commonAreaId}
            onChange={(event) => setCommonAreaId(event.target.value)}
          >
            {commonAreas.map((area) => (
              <option key={area.id} value={area.id}>
                {area.name} ({area.capacity} pessoas)
              </option>
            ))}
          </select>
        </label>

        {isLoading ? (
          <span className="rounded-full border border-neutral-700 px-2 py-0.5 text-xs text-neutral-300">
            Carregando
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
            Nenhuma reserva futura para {selectedArea?.name}.
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
                Dia inteiro
              </span>
            </div>
            <p className="text-sm text-neutral-300">
              {formatReservationDate(reservation.reservationDate)}
            </p>
            <p className="mt-1 text-xs text-neutral-500">{reservation.residentName}</p>
          </article>
        ))}
      </div>
    </section>
  );
}
