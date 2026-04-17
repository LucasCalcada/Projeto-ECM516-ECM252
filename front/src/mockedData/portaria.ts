import type { AccessEntryLog, AccessInvite, DeliveryPackage } from '../types/Portaria';

export const accessInvites: AccessInvite[] = [
  {
    id: 'visit-1',
    guestName: 'Bruno Almeida',
    guestDocument: 'RG 45.321.908-1',
    residentName: 'Joao Silva',
    apartment: 'Apto 41',
    validUntil: '2026-04-17T22:00:00',
    reason: 'Jantar em familia',
    status: 'active',
    token: 'PORT-41-BRUNO-2200',
  },
  {
    id: 'visit-2',
    guestName: 'Camila Rocha',
    guestDocument: 'CPF ***.456.789-**',
    residentName: 'Marina Costa',
    apartment: 'Apto 31',
    validUntil: '2026-04-18T18:30:00',
    reason: 'Reuniao do conselho',
    status: 'active',
    token: 'PORT-31-CAMILA-1830',
  },
];

export const deliveryPackages: DeliveryPackage[] = [
  {
    id: 'pkg-1',
    residentName: 'Carlos Silva',
    apartment: 'Apto 22',
    carrier: 'Correios',
    description: 'Caixa pequena',
    createdAt: '2026-04-17T09:15:00',
    status: 'arrived',
  },
  {
    id: 'pkg-2',
    residentName: 'Ana Paula',
    apartment: 'Apto 84',
    carrier: 'Mercado Livre',
    description: 'Envelope amarelo',
    createdAt: '2026-04-17T11:40:00',
    status: 'waiting',
  },
  {
    id: 'pkg-3',
    residentName: 'Joao Silva',
    apartment: 'Apto 41',
    carrier: 'Amazon',
    description: 'Pacote medio',
    createdAt: '2026-04-16T17:10:00',
    status: 'notified',
  },
];

export const accessEntryLogs: AccessEntryLog[] = [
  {
    id: 'entry-1',
    inviteId: 'visit-1',
    guestName: 'Bruno Almeida',
    guestDocument: 'RG 45.321.908-1',
    residentName: 'Joao Silva',
    apartment: 'Apto 41',
    enteredAt: '2026-04-17T19:12:00',
    porterName: 'Portaria principal',
  },
];
