import { InferInsertModel, InferSelectModel } from 'drizzle-orm';
import { pgTable, text, boolean, uuid } from 'drizzle-orm/pg-core';

export const accounts = pgTable('accounts', {
  id: uuid('id').primaryKey().notNull().defaultRandom(),
  name: text('name').notNull(),
  email: text('email').unique().notNull(),
  phone: text('phone').unique(),
  hashedPassword: text('password').notNull(),
  active: boolean('active'),
});

export type Account = InferSelectModel<typeof accounts>;
export type AccountInsert = InferInsertModel<typeof accounts>;
