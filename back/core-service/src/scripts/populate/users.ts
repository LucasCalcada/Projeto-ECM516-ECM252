import { UserInsert } from '@app/db/schema';
import { ids } from './ids';
import {
  AdminPermission,
  ReservationViewResidencyPermission,
  ReservationCreatePermission,
  UserManagePermission,
  ReservationViewBuildingPermission,
  DeliveryViewPermission,
  DeliveryListPermission,
} from '@app/permissions';

const commonUserPermissions = [
  ReservationCreatePermission,
  ReservationViewResidencyPermission,
  DeliveryViewPermission,
];

export const userData: UserInsert[] = [
  {
    accountId: ids.accounts.joao,
    residencyId: ids.residencies.ap101,
    buildingId: ids.buildings.jardim,
    name: 'João Silva',
    permissions: commonUserPermissions,
    active: true,
  },

  {
    accountId: ids.accounts.maria,
    residencyId: ids.residencies.ap102,
    buildingId: ids.buildings.jardim,
    name: 'Maria Silva',
    permissions: commonUserPermissions,
    active: true,
  },

  // mesma conta em dois condomínios

  {
    accountId: ids.accounts.carlos,
    residencyId: ids.residencies.ap201,
    buildingId: ids.buildings.jardim,
    name: 'Carlos Souza',
    permissions: commonUserPermissions,
    active: true,
  },

  {
    accountId: ids.accounts.carlos,
    residencyId: ids.residencies.casa01,
    buildingId: ids.buildings.bosque,
    name: 'Carlos Souza',
    permissions: commonUserPermissions,
    active: true,
  },

  // funcionários

  {
    accountId: ids.accounts.ana,
    residencyId: null,
    buildingId: ids.buildings.jardim,
    name: 'Ana Recepção',
    permissions: [UserManagePermission, ReservationViewBuildingPermission, DeliveryListPermission],
    active: true,
  },

  {
    accountId: ids.accounts.pedro,
    residencyId: null,
    buildingId: ids.buildings.jardim,
    name: 'Pedro Zelador',
    permissions: [],
    active: true,
  },

  {
    accountId: ids.accounts.fernanda,
    residencyId: null,
    buildingId: ids.buildings.jardim,
    name: 'Fernanda Síndica',
    permissions: [AdminPermission],
    active: true,
  },

  {
    accountId: ids.accounts.fernanda,
    residencyId: null,
    buildingId: ids.buildings.bosque,
    name: 'Fernanda Síndica',
    permissions: [AdminPermission],
    active: true,
  },
];
