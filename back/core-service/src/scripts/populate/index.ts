import building from '@app/db/schema/building';
import buildingData from './data/buildings';
import groupData from './data/groups';
import residencyData from './data/residencies';

import client from '@app/db/client';

async function populateDb() {
  console.log('Populating buildings...');
  await client.insert(building).values(buildingData);
}

populateDb();
