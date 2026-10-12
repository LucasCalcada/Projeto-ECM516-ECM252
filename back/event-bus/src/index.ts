import express from 'express';
import config from '@app/config';
import { setupRouter } from '@helpers/routeRegistry';
import errorMiddleware from './middlewares/error';
import './routes';
import log from './helpers/logger';
import loggerMiddleware from './middlewares/logger';

const app = express();
app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok' });
});
app.use(express.json());
app.use(loggerMiddleware);
setupRouter(app);
app.use(errorMiddleware);

app.listen(config.port, () => {
  log('SETUP', `EventBus started on port ${config.port}`);
});
