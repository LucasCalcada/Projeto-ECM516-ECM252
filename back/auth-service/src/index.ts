import express from 'express';
import config from '@app/config';
import { setupRouter } from '@helpers/routeRegistry';
import errorMiddleware from './middlewares/error';
import './routes';
import cors from 'cors';
import log from './helpers/logger';
import loggerMiddleware from './middlewares/logger';

const app = express();
app.use(cors());
app.use(express.json());
app.use(loggerMiddleware);
setupRouter(app);
app.use(errorMiddleware);

app.listen(config.port, () => {
  log('SETUP', `Core-service started on port ${config.port}`);
});
