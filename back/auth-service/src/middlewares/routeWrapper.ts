import { RouteHandler } from '@app/helpers/routeRegistry';
import { CookieOptions, Request, Response } from 'express';

export interface Context {
  req: Request;
  setCookie: (name: string, value: string, options: CookieOptions) => void;
}

export type WrappedRouteHandler = (req: Request, res: Response) => Promise<any>;

export default function wrapHandler(handler: RouteHandler): WrappedRouteHandler {
  return async (req: Request, res: Response) => {
    const ctx: Context = {
      req,
      setCookie: (name: string, value: string, options: CookieOptions) =>
        res.cookie(name, value, options),
    };

    const response = await handler(ctx);
    res.status(200);
    res.send(response);
  };
}
