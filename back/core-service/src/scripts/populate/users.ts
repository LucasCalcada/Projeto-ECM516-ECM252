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
  VisitorCreatePermission,
} from '@app/permissions';

const commonUserPermissions = [
  ReservationCreatePermission,
  ReservationViewResidencyPermission,
  DeliveryViewPermission,
  VisitorCreatePermission,
];

export const userData: UserInsert[] = [
  {
    id: ids.users.joao,
    accountId: ids.accounts.joao,
    residencyId: ids.residencies.ap101,
    buildingId: ids.buildings.jardim,
    name: 'João Silva',
    permissions: commonUserPermissions,
    active: true,
  },

  {
    id: ids.users.maria,
    accountId: ids.accounts.maria,
    residencyId: ids.residencies.ap102,
    buildingId: ids.buildings.jardim,
    name: 'Maria Silva',
    permissions: commonUserPermissions,
    active: true,
  },

  // mesma conta em dois condomínios

  {
    id: ids.users.carlos,
    accountId: ids.accounts.carlos,
    residencyId: ids.residencies.ap201,
    buildingId: ids.buildings.jardim,
    name: 'Carlos Souza',
    permissions: commonUserPermissions,
    active: true,
  },

  {
    id: ids.users.carlos2,
    accountId: ids.accounts.carlos,
    residencyId: ids.residencies.casa01,
    buildingId: ids.buildings.bosque,
    name: 'Carlos Souza',
    permissions: commonUserPermissions,
    active: true,
  },

  // funcionários

  {
    id: ids.users.ana,
    accountId: ids.accounts.ana,
    residencyId: null,
    buildingId: ids.buildings.jardim,
    name: 'Ana Recepção',
    permissions: [UserManagePermission, ReservationViewBuildingPermission, DeliveryListPermission],
    active: true,
  },

  {
    id: ids.users.pedro,
    accountId: ids.accounts.pedro,
    residencyId: null,
    buildingId: ids.buildings.jardim,
    name: 'Pedro Zelador',
    permissions: [],
    active: true,
  },

  {
    id: ids.users.fernanda,
    accountId: ids.accounts.fernanda,
    residencyId: null,
    buildingId: ids.buildings.jardim,
    name: 'Fernanda Síndica',
    permissions: [AdminPermission],
    active: true,
  },

  {
    id: ids.users.fernanda2,
    accountId: ids.accounts.fernanda,
    residencyId: null,
    buildingId: ids.buildings.bosque,
    name: 'Fernanda Síndica',
    permissions: [AdminPermission],
    active: true,
  },
];
