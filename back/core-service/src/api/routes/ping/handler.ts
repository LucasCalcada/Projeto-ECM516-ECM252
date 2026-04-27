import { Context } from '@app/middlewares/routeWrapper';
import { Request, Response } from 'express';

export default async function pingHandler(req: Request, ctx: Context) {
  return {
    message: 'Pong!',
  };
}
