import type { Express } from 'express';
import { Pool } from 'pg';
import config from '../config';

// Keep probe timeouts and connections independent of business queries.
const healthPool = new Pool({
  connectionString: config.dbConnectionString,
  max: 1,
  connectionTimeoutMillis: 1000,
  query_timeout: 1000,
  idleTimeoutMillis: 10000,
});
healthPool.on('error', () => {
  // A lost idle connection must not terminate the API.
});

export function setupHealthRoutes(app: Express) {
  app.get('/health/live', (_req, res) => {
    res.status(200).json({ status: 'ok' });
  });

  app.get('/health/ready', async (_req, res) => {
    try {
      await healthPool.query('SELECT 1');
      res.status(200).json({ status: 'ready' });
    } catch {
      res.status(503).json({ status: 'unavailable' });
    }
  });
}
