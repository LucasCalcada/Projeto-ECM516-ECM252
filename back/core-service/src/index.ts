import express from 'express';
import config from '@app/config';
import './api';
import { setupRouter } from './api/routeRegistry';

const app = express();
app.use(express.json());

setupRouter(app);

app.listen(config.port, () => {
  console.log(`Core-service started on port ${config.port}`);
});
