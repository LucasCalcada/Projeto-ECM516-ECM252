import { drizzle } from "drizzle-orm/node-postgres";
import config from "@app/config";
import { Pool } from "pg";

const pool = new Pool({
  connectionString: config.dbConnectionString,
});

const client = drizzle(pool);

export default client;
