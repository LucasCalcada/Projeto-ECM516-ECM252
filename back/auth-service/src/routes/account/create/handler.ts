import client from '@app/db/client';
import { accounts } from '@app/db/schema/account';
import hashPassword from '@app/helpers/hashPassword';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import { Context } from '@app/middlewares/routeWrapper';

export default async function createUser(ctx: Context) {
  const { name, password, phone, email } = ctx.req.body;
  const isMissingVar = [name, password, phone, email].some(
    (v) => v === undefined || v === '' || v === null,
  );

  if (isMissingVar) {
    throw BadRequest;
  }

  // TODO: validate email/phone
  // TODO: check for unique email/phone

  const hashedPassword = await hashPassword(password);

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
