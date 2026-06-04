import { UserInsert } from '@app/db/schema';
import { ids } from './ids';

const RESIDENT_RESERVATION_PERMISSIONS = ['@Reservation:Create', '@Reservation:ViewResidency'];
const STAFF_RESERVATION_PERMISSIONS = ['@Reservation:ViewBuilding'];

export const userData: UserInsert[] = [
  {
    accountId: ids.accounts.joao,
    residencyId: ids.residencies.ap101,
    buildingId: ids.buildings.jardim,
    name: 'João Silva',
    permissions: RESIDENT_RESERVATION_PERMISSIONS,
    active: true,
  },

  {
    accountId: ids.accounts.maria,
    residencyId: ids.residencies.ap102,
    buildingId: ids.buildings.jardim,
    name: 'Maria Silva',
    permissions: RESIDENT_RESERVATION_PERMISSIONS,
    active: true,
  },

  // mesma conta em dois condomínios

  {
    accountId: ids.accounts.carlos,
    residencyId: ids.residencies.ap201,
    buildingId: ids.buildings.jardim,
    name: 'Carlos Souza',
    permissions: RESIDENT_RESERVATION_PERMISSIONS,
    active: true,
  },

  {
    accountId: ids.accounts.carlos,
    residencyId: ids.residencies.casa01,
    buildingId: ids.buildings.bosque,
    name: 'Carlos Souza',
    permissions: RESIDENT_RESERVATION_PERMISSIONS,
    active: true,
  },

  // funcionários

  {
    accountId: ids.accounts.ana,
    residencyId: null,
    buildingId: ids.buildings.jardim,
    name: 'Ana Recepção',
    permissions: STAFF_RESERVATION_PERMISSIONS,
    active: true,
  },

  {
    accountId: ids.accounts.pedro,
    residencyId: null,
    buildingId: ids.buildings.jardim,
    name: 'Pedro Zelador',
    permissions: STAFF_RESERVATION_PERMISSIONS,
    active: true,
  },

  {
    accountId: ids.accounts.fernanda,
    residencyId: null,
    buildingId: ids.buildings.jardim,
    name: 'Fernanda Síndica',
    permissions: STAFF_RESERVATION_PERMISSIONS,
    active: true,
  },

  {
    accountId: ids.accounts.fernanda,
    residencyId: null,
    buildingId: ids.buildings.bosque,
    name: 'Fernanda Síndica',
    permissions: STAFF_RESERVATION_PERMISSIONS,
    active: true,
  },
];
