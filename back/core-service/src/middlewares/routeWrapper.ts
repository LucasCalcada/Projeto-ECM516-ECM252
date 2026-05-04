import { Request, Response } from 'express';
import authMiddleware from './auth';

export type WrappedRouteHandler = (req: Request, res: Response) => Promise<void>;

export interface Context {
  req: Request;
  auth: {
    token: string;
    accountId: string;
  };
}

export type RouteHandler = (req: Request, ctx: Context) => Promise<unknown>;

export default function wrapHandler(handler: RouteHandler): WrappedRouteHandler {
  return async (req: Request, res: Response) => {
    const auth = authMiddleware(req);

    const ctx: Context = {
      req,
      auth,
    };

    const response = await handler(req, ctx);

    res.status(200);
    if (response != undefined) {
      res.send(response);
    }
  };
}
