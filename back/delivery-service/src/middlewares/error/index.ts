import { NextFunction, Request, Response } from 'express';

export class ApiError extends Error {
  code: number;

  constructor(code: number, message: string) {
    super(message);
    this.code = code;
  }
}

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
