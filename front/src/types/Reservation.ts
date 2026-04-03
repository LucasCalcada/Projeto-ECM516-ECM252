export type ReservationStatus = 'confirmed' | 'pending' | 'cancelled';

export interface Reservation {
  id: string;
  residentName: string;
  commonAreaId: string;
  commonAreaName: string;
  date: string; // yyyy-mm-dd
  startTime: string; // HH:mm
  endTime: string; // HH:mm
  notes?: string;
  status: ReservationStatus;
}
