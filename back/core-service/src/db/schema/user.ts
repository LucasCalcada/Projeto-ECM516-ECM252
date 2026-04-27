import { InferInsertModel, InferSelectModel } from 'drizzle-orm';
import { pgTable, text, uuid, boolean } from 'drizzle-orm/pg-core';
import { residencies } from './residency';
import { buildings } from './building';

export const users = pgTable('users', {
  id: uuid('id').primaryKey().notNull().defaultRandom(),
  accountId: uuid('accountId').notNull(),
  residencyId: uuid('residencyId').references(() => residencies.id),
  buildingId: uuid('buildingId').references(() => buildings.id),
  name: text('name'),
  permissions: text('permissions').array(),
  active: boolean('active'),
});

export type User = InferSelectModel<typeof users>;
export type UserInsert = InferInsertModel<typeof users>;
