import { Request, Response } from 'express';

export default async function pingHandler(req: Request, res: Response) {
  res.status(200);
  res.send({ response: 'Pong!' });
}
