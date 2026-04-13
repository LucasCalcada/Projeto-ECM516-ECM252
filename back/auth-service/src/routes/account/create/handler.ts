import client from '@app/db/client';
import { accounts } from '@app/db/schema/account';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import { Request } from 'express';

export default async function createUser(req: Request) {
  const { name, hashedPassword, phone, email } = req.body;
  const isMissingVar = [name, hashedPassword, phone, email].some(
    (v) => v === undefined || v === '' || v === null,
  );

  if (isMissingVar) {
    throw BadRequest;
  }

  // TODO: validate email/phone
  // TODO: check for unique email/phone

  const [createdUser] = await client
    .insert(accounts)
    .values({
      name,
      hashedPassword,
      phone,
      email,
      active: true,
    })
    .returning();

  return {
    name: createdUser.name,
    phone: createdUser.phone,
    email: createdUser.email,
  };
}
