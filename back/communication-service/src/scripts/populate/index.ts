import client from '@app/db/client';

import { postSeedData } from './posts';
import { postResidencySeedData } from './postResidencies';

import { sql } from 'drizzle-orm';
import { postResidencies, posts } from '@app/db/schema/post';

async function clearDb() {
  await client.execute(sql`
    TRUNCATE TABLE
      post_residencies,
      posts
    CASCADE
  `);
}

async function seed() {
  await clearDb();

  console.log('Populating posts...');
  await client.insert(posts).values(postSeedData);

  console.log('Populating post residencies...');
  await client.insert(postResidencies).values(postResidencySeedData);

  console.log('Populate Finished');
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
