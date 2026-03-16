import { Pool } from "pg";
import config from "@app/config";
import { drizzle } from "drizzle-orm/singlestore/driver";

const postgresPool = new Pool({
  connectionString: config.dbConnectionString,
});

const client = drizzle({ client: postgresPool });

export default client;
