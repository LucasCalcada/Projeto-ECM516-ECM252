import type { Reservation } from '../types/Reservation';

const reservations: Reservation[] = [
  {
    id: 'res-1',
    residentName: 'Ana Paula - Apto 84',
    commonAreaId: 'bbq',
    commonAreaName: 'Churrasqueira',
    date: '2026-04-05',
    startTime: '12:00',
    endTime: '14:00',
    notes: 'Aniversario da filha',
    status: 'confirmed',
  },
  {
    id: 'res-2',
    residentName: 'Carlos Silva - Apto 22',
    commonAreaId: 'party-hall',
    commonAreaName: 'Salao de Festas',
    date: '2026-04-09',
    startTime: '18:00',
    endTime: '22:00',
    status: 'confirmed',
  },
  {
    id: 'res-3',
    residentName: 'Marina Costa - Apto 31',
    commonAreaId: 'meeting-room',
    commonAreaName: 'Sala de Reunioes',
    date: '2026-04-02',
    startTime: '19:00',
    endTime: '20:00',
    notes: 'Reuniao com conselho',
    status: 'pending',
  },
];

export default reservations;
