import { RouteHandler } from '@app/helpers/routeRegistry';
import { Request, Response } from 'express';

export type WrappedRouteHandler = (req: Request, res: Response) => Promise<void>;

export default function wrapHandler(handler: RouteHandler): WrappedRouteHandler {
  return async (req: Request, res: Response) => {
    const response = await handler(req);
    res.status(200);
    if (response != undefined) {
      res.send(response);
    }
  };
}
