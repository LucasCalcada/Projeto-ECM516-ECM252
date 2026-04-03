import express from 'express';
import config from '@app/config';

const app = express();
app.use(express.json());

app.listen(config.port, () => {
  console.log(`Core-service started on port ${config.port}`);
});
