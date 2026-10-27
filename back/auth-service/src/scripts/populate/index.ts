import { sql } from 'drizzle-orm';
import client from '@app/db/client';

import { accounts } from '@app/db/schema/account';
import { accountData } from './accounts';

async function clearDb() {
  await client.execute(sql`
    TRUNCATE TABLE accounts CASCADE
  `);
}

async function seed() {
  await clearDb();

  console.log('Populating accounts...');
  await client.insert(accounts).values(accountData);

  console.log('Auth service populate complete');
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
