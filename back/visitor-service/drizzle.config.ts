import { defineConfig } from 'drizzle-kit';
import config from './src/config';

export default defineConfig({
  dialect: 'postgresql',
  schema: './src/db/schema/access.ts',
  dbCredentials: {
    url: config.dbConnectionString,
  },
});
