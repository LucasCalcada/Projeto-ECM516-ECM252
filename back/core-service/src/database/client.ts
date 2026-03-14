import { Pool } from "pg";
import config from "@app/config";

const postgresPool = new Pool({
  connectionString: config.dbConnectionString,
});

export const query = async (q: string, params?: any[]) => {
  return postgresPool.query(q, params);
};
