export interface Group {
  id: string;
  building: string;
  name: string;
}

export interface Residency {
  id: string;
  groupId: string;
  code: string;
  name: string;
}

export interface User {
  id: string;
  accountId: string;
  residencyId: string;
  buildingId: string;
  name: string;
  permissions: string[];
  active: boolean;
}
