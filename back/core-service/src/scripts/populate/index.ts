import client from '@app/db/client';
import { buildings, groups, residencies, users } from '@app/db/schema';

import { buildingData } from './buildings';
import { groupData } from './groups';
import { residencyData } from './residencies';
import { userData } from './users';
import { sql } from 'drizzle-orm';

async function clearDb() {
  // Clear database
  await client.execute(sql`
    TRUNCATE TABLE
      users,
      residencies,
      groups,
      buildings
    CASCADE
  `);
}

async function seed() {
  await clearDb();

  console.log('Populating buildings...');
  await client.insert(buildings).values(buildingData);

  console.log('Populating groups...');
  await client.insert(groups).values(groupData);

  console.log('Populating residencies...');
  await client.insert(residencies).values(residencyData);

  console.log('Populating users...');
  await client.insert(users).values(userData);

  console.log('Populate Finished');
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
