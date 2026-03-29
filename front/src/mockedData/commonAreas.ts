import type { CommonArea } from '../types/CommonArea';

const commonAreas: CommonArea[] = [
  {
    id: 'bbq',
    name: 'Churrasqueira',
    capacity: 20,
    openingHour: '10:00',
    closingHour: '22:00',
    reservationSlotMinutes: 120,
  },
  {
    id: 'party-hall',
    name: 'Salao de Festas',
    capacity: 60,
    openingHour: '08:00',
    closingHour: '23:00',
    reservationSlotMinutes: 240,
  },
  {
    id: 'meeting-room',
    name: 'Sala de Reunioes',
    capacity: 12,
    openingHour: '08:00',
    closingHour: '20:00',
    reservationSlotMinutes: 60,
  },
];

export default commonAreas;
