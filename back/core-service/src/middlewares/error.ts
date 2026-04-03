import { ApiError } from '@app/api/error';
import { NextFunction, Request, Response } from 'express';

export default function errorMiddleware(
  err: unknown,
  req: Request,
  res: Response,
  next: NextFunction,
) {
  if (err instanceof ApiError) {
    res.status(err.code).send({ message: err.message });
  } else {
    res.status(500).send({ message: 'Internal server error' });
  }
}
