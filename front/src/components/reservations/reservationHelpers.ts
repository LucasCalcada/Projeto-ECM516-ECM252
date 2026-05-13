import type { Reservation } from '../../types/Reservation';

export interface ApiReservation {
  id: string;
  residentName: string;
  apartment?: string;
  buildingName?: string;
  commonAreaId: string;
  commonAreaName: string;
  reservationDate: string;
  notes?: string | null;
  status: 'CONFIRMED' | 'CANCELED';
}

export function formatReservationDate(date: string): string {
  return new Date(`${date}T00:00:00`).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
}

export function getTimeUntilReservation(dateStr: string): string {
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

export function mapApiReservation(reservation: ApiReservation): Reservation {
  return {
    id: reservation.id,
    residentName: reservation.residentName,
    commonAreaId: reservation.commonAreaId,
    commonAreaName: reservation.commonAreaName,
    date: reservation.reservationDate,
    startTime: '00:00',
    endTime: '23:59',
    notes: reservation.notes ?? undefined,
    status: reservation.status === 'CONFIRMED' ? 'confirmed' : 'cancelled',
  };
}

export function getAccessToken(): string {
  return localStorage.getItem('accessToken') ?? '';
}
