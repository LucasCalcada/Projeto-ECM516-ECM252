import { Request, Response, type Express } from 'express';

export interface Route {
  method: 'get' | 'post' | 'put' | 'delete';
  path: string;
  handler: (req: Request, res: Response) => void;
}

const routes: Route[] = [];

export function registerRoute(route: Route) {
  routes.push(route);
}

export function setupRouter(app: Express) {
  routes.forEach((r) => {
    console.log(`Registered route ${r.method} ${r.path}`);
    app[r.method](r.path, r.handler);
  });
}
