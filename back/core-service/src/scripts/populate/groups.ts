import { GroupInsert } from '@app/db/schema';
import { ids } from './ids';

export const groupData: GroupInsert[] = [
  {
    id: ids.groups.torreA,
    building: ids.buildings.jardim,
    name: 'Torre A',
  },

  {
    id: ids.groups.torreB,
    building: ids.buildings.jardim,
    name: 'Torre B',
  },

  {
    id: ids.groups.palmeiras,
    building: ids.buildings.bosque,
    name: 'Rua das Palmeiras',
  },

  {
    id: ids.groups.acacias,
    building: ids.buildings.bosque,
    name: 'Rua das Acácias',
  },
];
