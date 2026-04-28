import { type Express } from 'express';
import wrapHandler, { Context } from '../middlewares/routeWrapper';
import log from './logger';

export type RouteHandler = (ctx: Context) => Promise<any>;

export interface Route {
  method: 'get' | 'post' | 'put' | 'delete';
  path: string;
  handler: RouteHandler;
}

const routes: Route[] = [];

export function registerRoute(route: Route) {
  routes.push(route);
}

export function setupRouter(app: Express) {
  routes.forEach((r) => {
    const wrappedHandler = wrapHandler(r.handler);
    app[r.method](r.path, wrappedHandler);
    log('SETUP', `Registered route ${r.method} ${r.path}`);
  });
}
