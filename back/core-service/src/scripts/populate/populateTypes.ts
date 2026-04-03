export interface PopulateUser {
  name: string;
  permissions: string[];
  active: boolean;
}

export interface PopulateResidency {
  code: string;
  name: string;
  users: PopulateUser[];
}

export interface PopulateGroup {
  name: string;
  residencies: PopulateResidency[];
}

export interface PopulateBuilding {
  name: string;
  active: boolean;
  groups: PopulateGroup[];
  employees: PopulateUser[];
}
