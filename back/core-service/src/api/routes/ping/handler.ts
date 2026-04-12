import { Request, Response } from 'express';

export default async function pingHandler(req: Request) {
  return {
    message: 'Pong!',
  };
}
