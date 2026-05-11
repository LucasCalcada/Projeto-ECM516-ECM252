import { Request, Response } from 'express';
import { validateAuthToken } from './auth';
import { AuthToken } from '@app/types/auth';

export type WrappedRouteHandler = (req: Request, res: Response) => Promise<any>;

export interface Context {
  req: Request;
  token: AuthToken;
}

export type RouteHandler = (req: Request, ctx: Context) => Promise<any>;

export default function wrapHandler(handler: RouteHandler): WrappedRouteHandler {
  return async (req: Request, res: Response) => {
    const authToken = validateAuthToken(req);

    const ctx: Context = {
      req,
      token: authToken.token,
    };

    const response = await handler(req, ctx);

    res.status(200);
    if (response != undefined) {
      res.send(response);
    }
  };
}
