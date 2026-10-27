import { BuildingInsert } from '@app/db/schema/building';
import { ids } from './ids';

export const buildingData: BuildingInsert[] = [
  {
    id: ids.buildings.jardim,
    name: 'Edifício Jardim das Flores',
    active: true,
  },

  {
    id: ids.buildings.bosque,
    name: 'Condomínio Residencial Bosque Verde',
    active: true,
  },
];
