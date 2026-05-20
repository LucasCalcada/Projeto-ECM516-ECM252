import express from 'express';
import cors from 'cors';
import config from '@app/config';
import { setupRouter } from '@helpers/routeRegistry';
import errorMiddleware from './middlewares/error';
import loggerMiddleware from './middlewares/logger';
import log from './helpers/logger';
import './routes';

const app = express();

app.use(cors());
app.use(express.json());
app.use(loggerMiddleware);

setupRouter(app);

app.use(errorMiddleware);

app.listen(config.port, () => {
  log('SETUP', `Communication-service started on port ${config.port}`);
});
