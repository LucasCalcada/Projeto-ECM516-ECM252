import { ResidencyInsert } from '@app/db/schema';
import { ids } from './ids';

export const residencyData: ResidencyInsert[] = [
  {
    id: ids.residencies.ap101,
    groupId: ids.groups.torreA,
    code: '101A',
    name: 'Apartamento 101',
  },

  {
    id: ids.residencies.ap102,
    groupId: ids.groups.torreA,
    code: '102A',
    name: 'Apartamento 102',
  },

  {
    id: ids.residencies.ap201,
    groupId: ids.groups.torreB,
    code: '101B',
    name: 'Apartamento 101',
  },

  {
    id: ids.residencies.casa01,
    groupId: ids.groups.palmeiras,
    code: '01',
    name: 'Casa 01',
  },

  {
    id: ids.residencies.casa02,
    groupId: ids.groups.palmeiras,
    code: '02',
    name: 'Casa 02',
  },

  {
    id: ids.residencies.casa10,
    groupId: ids.groups.acacias,
    code: '10',
    name: 'Casa 10',
  },
];
