import { Pool } from 'pg';
import config from '../config';
import { drizzle } from 'drizzle-orm/node-postgres';

const postgresPool = new Pool({
  connectionString: config.dbConnectionString,
});

const client = drizzle({ client: postgresPool });

export default client;
