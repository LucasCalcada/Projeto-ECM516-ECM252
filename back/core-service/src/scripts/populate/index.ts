import client from '@db/client';
import { buildings, groups, residencies, users } from '@app/db/schema';

import { PopulateBuilding, PopulateGroup, PopulateResidency, PopulateUser } from './populateTypes';
import populateData from './populateData';

async function populateUsers(
  data: PopulateUser,
  residencyId: string | null,
  buildingId: string | null,
) {
  const { name, permissions, active } = data;

  await client.insert(users).values({
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
    .insert(residencies)
    .values({
      groupId,
      name,
      code,
    })
    .returning();

  await Promise.all(data.users.map((u) => populateUsers(u, residencyRow.id, null)));
}

async function populateGroups(data: PopulateGroup, buildingId: string) {
  const { name } = data;

  const [groupRow] = await client
    .insert(groups)
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
    .insert(buildings)
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
  await client.delete(users);
  await client.delete(residencies);
  await client.delete(groups);
  await client.delete(buildings);
  console.log('Populating buildings...');
  await Promise.all(populateData.map(populateBuilding));
}

populateDb();
