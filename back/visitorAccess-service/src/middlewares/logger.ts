import log from '@app/helpers/logger';
import { Request, Response, NextFunction } from 'express';

export default function loggerMiddleware(req: Request, res: Response, next: NextFunction) {
  log('REQUEST', `${req.method} ${req.path}`);
  next();
}
