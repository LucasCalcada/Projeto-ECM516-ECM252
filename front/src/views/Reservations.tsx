import { type FormEvent, useMemo, useState } from 'react';
import commonAreas from '../mockedData/commonAreas';
import initialReservations from '../mockedData/reservations';
import type { Reservation } from '../types/Reservation';

interface NewReservationForm {
  residentName: string;
  commonAreaId: string;
  date: string;
  startTime: string;
  endTime: string;
  notes: string;
}

function asDateTime(date: string, time: string): Date {
  return new Date(`${date}T${time}:00`);
}

function hasTimeConflict(
  candidate: Reservation,
  existing: Reservation[],
): boolean {
  const candidateStart = asDateTime(
    candidate.date,
    candidate.startTime,
  ).getTime();
  const candidateEnd = asDateTime(candidate.date, candidate.endTime).getTime();

  return existing.some((r) => {
    if (r.status === 'cancelled') {
      return false;
    }

    if (
      r.commonAreaId !== candidate.commonAreaId ||
      r.date !== candidate.date
    ) {
      return false;
    }

    const existingStart = asDateTime(r.date, r.startTime).getTime();
    const existingEnd = asDateTime(r.date, r.endTime).getTime();

    return candidateStart < existingEnd && candidateEnd > existingStart;
  });
}

function formatDate(date: string): string {
  return new Date(`${date}T00:00:00`).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
}

export default function Reservations() {
  const [reservations, setReservations] =
    useState<Reservation[]>(initialReservations);
  const [feedback, setFeedback] = useState<string>('');
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
      const first = asDateTime(a.date, a.startTime).getTime();
      const second = asDateTime(b.date, b.startTime).getTime();
      return first - second;
    });
  }, [reservations]);

  const selectedArea = commonAreas.find(
    (area) => area.id === form.commonAreaId,
  );

  function onInputChange<K extends keyof NewReservationForm>(
    key: K,
    value: NewReservationForm[K],
  ) {
    setForm((prev) => ({ ...prev, [key]: value }));
  }

  function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!form.residentName || !form.date || !form.startTime || !form.endTime) {
      setFeedback('Preencha todos os campos obrigatorios.');
      return;
    }

    const start = asDateTime(form.date, form.startTime).getTime();
    const end = asDateTime(form.date, form.endTime).getTime();

    if (start >= end) {
      setFeedback('O horario final precisa ser maior que o inicial.');
      return;
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
      startTime: form.startTime,
      endTime: form.endTime,
      notes: form.notes.trim() || undefined,
      status: 'pending',
    };

    if (hasTimeConflict(newReservation, reservations)) {
      setFeedback('Conflito de horario com uma reserva existente.');
      return;
    }

    setReservations((prev) => [...prev, newReservation]);
    setFeedback('Reserva criada com sucesso e enviada para aprovacao.');
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
    <div className='h-full p-4 md:p-8'>
      <div className='mb-6'>
        <h1 className='text-2xl font-bold text-neutral-100'>
          Reservas de Areas Comuns
        </h1>
        <p className='text-neutral-400'>
          Gerencie reservas de churrasqueira, salao de festas e demais
          ambientes.
        </p>
      </div>

      <div className='grid grid-cols-1 gap-4 lg:grid-cols-5'>
        <section className='rounded-xl border border-neutral-800 bg-neutral-900/40 p-4 lg:col-span-3'>
          <h2 className='mb-3 text-lg font-semibold'>Proximas reservas</h2>
          <div className='space-y-3'>
            {upcomingReservations.map((reservation) => (
              <article
                key={reservation.id}
                className='rounded-lg border border-neutral-800 bg-neutral-950 p-3'
              >
                <div className='flex flex-wrap items-center justify-between gap-2'>
                  <p className='font-medium text-neutral-100'>
                    {reservation.commonAreaName}
                  </p>
                  <span className='rounded-full border border-neutral-700 px-2 py-0.5 text-xs text-neutral-300'>
                    {reservation.status}
                  </span>
                </div>
                <p className='text-sm text-neutral-300'>
                  {formatDate(reservation.date)} - {reservation.startTime} as{' '}
                  {reservation.endTime}
                </p>
                <p className='text-sm text-neutral-400'>
                  {reservation.residentName}
                </p>
                {reservation.notes ? (
                  <p className='mt-1 text-sm text-neutral-500'>
                    Obs: {reservation.notes}
                  </p>
                ) : null}
              </article>
            ))}
          </div>
        </section>

        <section className='rounded-xl border border-neutral-800 bg-neutral-900/40 p-4 lg:col-span-2'>
          <h2 className='mb-3 text-lg font-semibold'>Nova reserva</h2>
          <form className='space-y-3' onSubmit={onSubmit}>
            <label className='block'>
              <span className='mb-1 block text-sm text-neutral-300'>
                Morador
              </span>
              <input
                className='w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm'
                value={form.residentName}
                onChange={(e) => onInputChange('residentName', e.target.value)}
                placeholder='Ex.: Joao - Apto 41'
              />
            </label>

            <label className='block'>
              <span className='mb-1 block text-sm text-neutral-300'>
                Area comum
              </span>
              <select
                className='w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm'
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
              <p className='text-xs text-neutral-500'>
                Horario de funcionamento: {selectedArea.openingHour} as{' '}
                {selectedArea.closingHour}
              </p>
            ) : null}

            <div className='grid grid-cols-1 gap-3 md:grid-cols-2'>
              <label className='block'>
                <span className='mb-1 block text-sm text-neutral-300'>
                  Data
                </span>
                <input
                  type='date'
                  className='w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm'
                  value={form.date}
                  onChange={(e) => onInputChange('date', e.target.value)}
                />
              </label>
              <label className='block'>
                <span className='mb-1 block text-sm text-neutral-300'>
                  Inicio
                </span>
                <input
                  type='time'
                  className='w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm'
                  value={form.startTime}
                  onChange={(e) => onInputChange('startTime', e.target.value)}
                />
              </label>
            </div>

            <label className='block'>
              <span className='mb-1 block text-sm text-neutral-300'>Fim</span>
              <input
                type='time'
                className='w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm'
                value={form.endTime}
                onChange={(e) => onInputChange('endTime', e.target.value)}
              />
            </label>

            <label className='block'>
              <span className='mb-1 block text-sm text-neutral-300'>
                Observacao (opcional)
              </span>
              <textarea
                className='min-h-20 w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm'
                value={form.notes}
                onChange={(e) => onInputChange('notes', e.target.value)}
              />
            </label>

            <button
              type='submit'
              className='w-full rounded-md bg-neutral-100 px-3 py-2 text-sm font-medium text-neutral-900 transition hover:bg-white'
            >
              Solicitar reserva
            </button>
          </form>

          {feedback ? (
            <p className='mt-3 text-sm text-neutral-300'>{feedback}</p>
          ) : null}
        </section>
      </div>
    </div>
  );
}
