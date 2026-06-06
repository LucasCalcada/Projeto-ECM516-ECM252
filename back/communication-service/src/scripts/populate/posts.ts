import { ids } from './ids';
import { type PostInsert } from '@app/db/schema/post';

export const postSeedData: PostInsert[] = [
  {
    id: '55555555-5555-5555-5555-555555555551',
    buildingId: ids.buildings.jardim,
    authorUserId: ids.accounts.joao,
    title: 'Manutenção da caixa d’água',
    description: 'Na próxima sexta-feira haverá manutenção da caixa d’água.',
    eventAt: new Date('2026-06-12T08:00:00'),
  },

  {
    id: '55555555-5555-5555-5555-555555555552',
    buildingId: ids.buildings.jardim,
    authorUserId: ids.accounts.maria,
    title: 'Festa Junina do condomínio',
    description: 'Todos os moradores estão convidados para a festa junina.',
    eventAt: new Date('2026-06-20T18:00:00'),
  },

  {
    id: '55555555-5555-5555-5555-555555555553',
    buildingId: ids.buildings.bosque,
    authorUserId: ids.accounts.carlos,
    title: 'Poda das árvores',
    description: 'A equipe de jardinagem realizará a poda das árvores.',
    eventAt: new Date('2026-06-15T09:00:00'),
  },

  {
    id: '55555555-5555-5555-5555-555555555554',
    buildingId: ids.buildings.bosque,
    authorUserId: ids.accounts.ana,
    title: 'Assembleia extraordinária',
    description: 'Assembleia para discutir melhorias na segurança.',
    eventAt: new Date('2026-06-25T19:30:00'),
  },

  {
    id: '55555555-5555-5555-5555-555555555555',
    buildingId: ids.buildings.jardim,
    authorUserId: ids.accounts.pedro,
    title: 'Vaga de garagem bloqueada',
    description: 'A vaga próxima à entrada principal ficará interditada.',
  },
] as const;
