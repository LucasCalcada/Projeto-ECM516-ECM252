import { InferInsertModel, InferSelectModel } from 'drizzle-orm';
import { pgTable, text, boolean, uuid } from 'drizzle-orm/pg-core';

export const accounts = pgTable('accounts', {
  id: uuid('id').primaryKey().notNull().defaultRandom(),
  name: text('name'),
  email: text('email').unique(),
  phone: text('phone').unique(),
  hashedPassword: text('password'),
  active: boolean('active'),
});

export type Account = InferSelectModel<typeof accounts>;
export type AccountInsert = InferInsertModel<typeof accounts>;
