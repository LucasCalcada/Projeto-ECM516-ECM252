import { PopulateBuilding } from './populateTypes';

const populateData: PopulateBuilding[] = [
  {
    name: 'Prédio 1',
    active: true,
    groups: [
      {
        name: 'Torre A',
        residencies: [
          {
            name: 'Apt 01A',
            code: '01',
            users: [
              {
                name: 'João',
                permissions: [],
                active: true,
              },
            ],
          },
          {
            name: 'Apt 02A',
            code: '02',
            users: [
              {
                name: 'Pedro',
                permissions: [],
                active: true,
              },
            ],
          },
        ],
      },
      {
        name: 'Torre B',
        residencies: [
          {
            name: 'Apt 01B',
            code: '01',
            users: [
              {
                name: 'Felipe',
                permissions: [],
                active: true,
              },
            ],
          },
          {
            name: 'Apt 02B',
            code: '02',
            users: [
              {
                name: 'Matheus',
                permissions: [],
                active: true,
              },
            ],
          },
        ],
      },
    ],
    employees: [
      {
        name: 'Síndico Paulo',
        permissions: [],
        active: true,
      },
      {
        name: 'Porteiro Carlos',
        permissions: [],
        active: true,
      },
    ],
  },
  {
    name: 'Condomínio 1',
    active: true,
    groups: [
      {
        name: 'Rua A',
        residencies: [
          {
            name: 'Casa 01A',
            code: '01',
            users: [
              {
                name: 'João',
                permissions: [],
                active: true,
              },
            ],
          },
          {
            name: 'Casa 02A',
            code: '02',
            users: [
              {
                name: 'Pedro',
                permissions: [],
                active: true,
              },
            ],
          },
        ],
      },
      {
        name: 'Rua B',
        residencies: [
          {
            name: 'Casa 01B',
            code: '01',
            users: [
              {
                name: 'Felipe',
                permissions: [],
                active: true,
              },
            ],
          },
          {
            name: 'Casa 02B',
            code: '02',
            users: [
              {
                name: 'Matheus',
                permissions: [],
                active: true,
              },
            ],
          },
        ],
      },
    ],
    employees: [
      {
        name: 'Porteiro Lucas',
        permissions: [],
        active: true,
      },
    ],
  },
];
export default populateData;
