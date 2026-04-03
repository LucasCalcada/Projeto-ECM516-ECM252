import client from '@db/client';
import building from '@schema/building';
import group from '@schema/group';
import user from '@schema/user';
import residency from '@schema/residency';

import { PopulateBuilding, PopulateGroup, PopulateResidency, PopulateUser } from './populateTypes';
import populateData from './populateData';

async function populateUsers(
  data: PopulateUser,
  residencyId: string | null,
  buildingId: string | null,
) {
  const { name, permissions, active } = data;

  await client.insert(user).values({
    name,
    permissions,
    active,
    residencyId,
    buildingId,
  });
}

async function populateResidencies(data: PopulateResidency, groupId: string) {
  const { code, name } = data;

  const [residencyRow] = await client
    .insert(residency)
    .values({
      groupId,
      name,
      code,
    })
    .returning();

  await Promise.all(data.users.map((u) => populateUsers(u, residencyRow.id, null)));
}

async function populateGroups(data: PopulateGroup, buildingId: any) {
  const { name } = data;

  const [groupRow] = await client
    .insert(group)
    .values({
      building: buildingId,
      name,
    })
    .returning();

  await Promise.all(data.residencies.map((r) => populateResidencies(r, groupRow.id)));
}

async function populateBuilding(data: PopulateBuilding) {
  const { name, active } = data;

  const [buildingRow] = await client
    .insert(building)
    .values({
      name,
      active,
    })
    .returning();

  await Promise.all(data.groups.map((g) => populateGroups(g, buildingRow.id)));
  await Promise.all(data.employees.map((e) => populateUsers(e, null, buildingRow.id)));
}

async function populateDb() {
  console.log('Clearing old data...');
  await client.delete(user);
  await client.delete(residency);
  await client.delete(group);
  await client.delete(building);
  console.log('Populating buildings...');
  await Promise.all(populateData.map(populateBuilding));
}

populateDb();
