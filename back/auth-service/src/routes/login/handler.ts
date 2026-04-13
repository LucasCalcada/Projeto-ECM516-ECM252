import client from '@app/db/client';
import { accounts } from '@app/db/schema/account';
import { eq } from 'drizzle-orm';
import { Request } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import Unauthorized from '@app/middlewares/error/errors/Unauthorized';
import config from '@app/config';

export default async function authenticateUser(req: Request) {
  const { email, password } = req.body;

  if (!email || !password) {
    throw BadRequest;
  }

  const [account] = await client.select().from(accounts).where(eq(accounts.email, email));

  if (!account) {
    throw Unauthorized;
  }

  const valid = await bcrypt.compare(password, account.hashedPassword);
  if (!valid) {
    throw Unauthorized;
  }

  const data = {
    id: account.id,
    email: account.email,
  };

  const token = jwt.sign(data, config.jwtToken, { expiresIn: '1h' });

  return { token };
}
