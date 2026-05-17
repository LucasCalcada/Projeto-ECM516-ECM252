import { NextFunction, Request, Response } from 'express';
import log from '../helpers/logger';

export default function loggerMiddleware(req: Request, res: Response, next: NextFunction) {
  log('REQUEST', `${req.method} ${req.path}`);
  next();
}
