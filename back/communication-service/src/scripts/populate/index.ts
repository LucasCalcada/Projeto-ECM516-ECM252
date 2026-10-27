import client from '@app/db/client';

import { postSeedData } from './posts';
import { postRecipientSeedData } from './postRecipients';

import { sql } from 'drizzle-orm';
import { postRecipients, posts } from '@app/db/schema/post';

async function clearDb() {
  await client.execute(sql`
    TRUNCATE TABLE
      post_recipients,
      posts
    CASCADE
  `);
}

async function seed() {
  await clearDb();

  console.log('Populating posts...');
  await client.insert(posts).values(postSeedData);

  console.log('Populating post recipients...');
  await client.insert(postRecipients).values(postRecipientSeedData);

  console.log('Populate Finished');
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
