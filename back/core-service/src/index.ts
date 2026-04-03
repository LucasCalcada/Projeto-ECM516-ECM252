import express from 'express';
import config from '@app/config';
import { setupRouter } from '@helpers/routeRegistry';
import errorMiddleware from './middlewares/error';
import './api';

const app = express();
app.use(express.json());
setupRouter(app);
app.use(errorMiddleware);

app.listen(config.port, () => {
  console.log(`Core-service started on port ${config.port}`);
});
