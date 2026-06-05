export type ReservationStatus = 'confirmed' | 'pending' | 'cancelled';

export interface Reservation {
  id: string;
  residentName: string;
  commonAreaId: string;
  commonAreaName: string;
  date: string; // yyyy-mm-dd
}

export interface ReservationApiResponse {
  id: string;
  residentName: string;
  commonAreaId: string;
  commonAreaName: string;
  reservationDate: string;
}

export function mapReservationApiResponse(reservation: ReservationApiResponse): Reservation {
  return {
    id: reservation.id,
    residentName: reservation.residentName,
    commonAreaId: reservation.commonAreaId,
    commonAreaName: reservation.commonAreaName,
    date: reservation.reservationDate,
  };
}
