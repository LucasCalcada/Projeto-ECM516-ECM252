import client from '@app/db/client';
import { accounts } from '@app/db/schema/account';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import { Context } from '@app/middlewares/routeWrapper';
import { eq } from 'drizzle-orm';

export default async function updateAccount(ctx: Context) {
  const { id, name } = ctx.req.body;

  if (!id) {
    throw BadRequest;
  }

  const [updatedAccount] = await client
    .update(accounts)
    .set({ name })
    .where(eq(accounts.id, id))
    .returning();

  return {
    id,
    name: updatedAccount.name,
    email: updatedAccount.email,
    phone: updatedAccount.phone,
  };
}
