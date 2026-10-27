import client from '@app/db/client';
import { commonAreas } from '@app/db/schema/reservation';
import { sql } from 'drizzle-orm';
import { commonAreaData } from './commonAreas';

async function clearDb() {
  await client.execute(sql`
    TRUNCATE TABLE
      reservations,
      common_areas
    CASCADE
  `);
}

async function seed() {
  await clearDb();

  console.log('Populating common areas...');
  await client.insert(commonAreas).values(commonAreaData);

  console.log('Populate Finished');
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
