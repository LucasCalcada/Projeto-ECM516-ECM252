import { defineConfig } from 'drizzle-kit';
import config from './src/config';

export default defineConfig({
  dialect: 'postgresql',
  schema: './src/db/schema/package.ts',
  dbCredentials: {
    url: config.dbConnectionString,
  },
});
