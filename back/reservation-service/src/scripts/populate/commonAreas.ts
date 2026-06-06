import { CommonAreaInsert } from '@app/db/schema/reservation';
import { ids } from './ids';

export const commonAreaData: CommonAreaInsert[] = [
  {
    id: ids.commonAreas.jardimChurrasqueira,
    buildingId: ids.buildings.jardim,
    name: 'Churrasqueira',
    limit: 20,
  },
  {
    id: ids.commonAreas.jardimSalaoFestas,
    buildingId: ids.buildings.jardim,
    name: 'Salão de Festas',
    limit: 60,
  },
  {
    id: ids.commonAreas.jardimSalaReuniao,
    buildingId: ids.buildings.jardim,
    name: 'Sala de Reunião',
    limit: 12,
  },
  {
    id: ids.commonAreas.bosqueChurrasqueira,
    buildingId: ids.buildings.bosque,
    name: 'Churrasqueira',
    limit: 16,
  },
  {
    id: ids.commonAreas.bosqueSalaoFestas,
    buildingId: ids.buildings.bosque,
    name: 'Salão de Festas',
    limit: 50,
  },
  {
    id: ids.commonAreas.bosqueSalaReuniao,
    buildingId: ids.buildings.bosque,
    name: 'Sala de Reunião',
    limit: 10,
  },
];
